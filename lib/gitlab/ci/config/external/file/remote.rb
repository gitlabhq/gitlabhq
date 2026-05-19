# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        module File
          class Remote < Base
            include Gitlab::Utils::StrongMemoize

            def initialize(params, context)
              @location = params[:remote]

              super
            end

            def preload_content
              fetch_async_content
            end

            def content
              body = fetch_body_with_cache

              return unless body

              verify_integrity(body) if params[:integrity]

              return if errors.any?

              body
            end
            strong_memoize_attr :content

            def include_type
              :remote
            end

            def metadata
              super.merge(
                location: masked_location,
                blob: nil,
                raw: masked_location,
                extra: {}
              )
            end

            def validate_context!
              # no-op
            end

            def validate_location!
              super

              unless ::Gitlab::UrlSanitizer.valid?(location)
                errors.push("Remote file `#{masked_location}` does not have a valid address!")
              end
            end

            private

            def fetch_body_with_cache
              start_time = Time.current

              if cache_enabled?
                cache_hit = Rails.cache.exist?(cache_key)

                result = Rails.cache.fetch(cache_key, expires_in: cache_ttl) do
                  fetch_response_body
                end

                log_cache_access(cache_hit: cache_hit, duration: Time.current - start_time)
              else
                result = fetch_response_body
                log_cache_access(cache_hit: false, duration: Time.current - start_time) if params[:cache].present?
              end

              result
            end

            def cache_enabled?
              params[:cache].present?
            end

            def cache_key
              "ci-remote-include::#{location}"
            end

            def cache_ttl
              return 1.hour unless params[:cache].is_a?(String)

              ChronicDuration.parse(params[:cache]).seconds
            end

            def fetch_response_body
              response = fetch_with_error_handling do
                fetch_async_content.value
              end

              response&.body
            end

            def fetch_async_content
              # It starts fetching the remote content in a separate thread and returns a lazy_response immediately.
              Gitlab::HTTP.get(location, http_options).tap do |lazy_response|
                context.execute_remote_parallel_request(lazy_response)
              end
            end
            strong_memoize_attr :fetch_async_content

            def http_options
              options = { async: true }

              if Feature.enabled?(:ci_config_http_timeout, context.project)
                options.merge!(
                  open_timeout: Config::HTTP_OPEN_TIMEOUT_SECONDS,
                  read_timeout: Config::HTTP_READ_TIMEOUT_SECONDS,
                  write_timeout: 30, # This is the default value today
                  timeout: Config::HTTP_READ_TIMEOUT_SECONDS
                )
              end

              options
            end

            def fetch_with_error_handling
              max_attempts = 3
              attempt = 0

              loop do
                attempt += 1
                clear_memoization(:fetch_async_content) if attempt > 1

                begin
                  # Even with per-request HTTP timeouts, retries can accumulate beyond the
                  # overall config-fetch deadline, so we check the elapsed execution time
                  # before each attempt and fail fast with a TimeoutError when expired.
                  context.check_execution_time! if Feature.enabled?(:ci_config_http_timeout, context.project)

                  response = yield

                  if response.nil?
                    errors.push("Remote file `#{masked_location}` could not be fetched because the response was empty!")
                    break
                  end

                  if response.code.to_i >= 400 && retry_or_add_error_for_response(response.code.to_i, attempt, max_attempts)
                    next
                  end

                  return response if errors.none?
                rescue SocketError
                  if retry_or_add_error(attempt, max_attempts, "Remote file `#{masked_location}` could not be fetched after #{max_attempts} attempts because of a socket error!")
                    next
                  end
                rescue Timeout::Error, *Gitlab::HTTP::HTTP_TIMEOUT_ERRORS
                  if should_retry_error?(attempt, max_attempts)
                    sleep(backoff_delay(attempt))
                    next
                  end

                  log_http_timeout
                  raise Context::HTTPTimeoutError, "Remote file `#{masked_location}` could not be fetched after #{max_attempts} attempts because of a timeout error!"
                rescue Gitlab::HTTP::Error
                  if retry_or_add_error(attempt, max_attempts, "Remote file `#{masked_location}` could not be fetched after #{max_attempts} attempts because of HTTP error!")
                    next
                  end
                rescue Errno::ECONNREFUSED, Gitlab::HTTP::BlockedUrlError => e
                  errors.push("Remote file could not be fetched because #{e}!")
                end

                break
              end

              nil
            end

            def retry_or_add_error_for_response(code, attempt, max_attempts)
              if should_retry_response?(code, attempt, max_attempts)
                sleep(backoff_delay(attempt))
                return true
              end

              errors.push("Remote file `#{masked_location}` could not be fetched after #{attempt} #{'attempt'.pluralize(attempt)} because of HTTP code `#{code}` error!")
              false
            end

            def retry_or_add_error(attempt, max_attempts, error_message)
              if should_retry_error?(attempt, max_attempts)
                sleep(backoff_delay(attempt))
                return true
              end

              errors.push(error_message)
              false
            end

            def should_retry_response?(code, attempt, max_attempts)
              attempt < max_attempts && code >= 500
            end

            def should_retry_error?(attempt, max_attempts)
              attempt < max_attempts
            end

            def backoff_delay(attempt)
              # Returns exponential backoff delay in seconds
              # After attempt 1 fails: 2^0 = 1s
              # After attempt 2 fails: 2^1 = 2s
              2**(attempt - 1)
            end

            def log_cache_access(cache_hit:, duration:)
              Gitlab::AppJsonLogger.info(
                message: 'CI remote include cache access',
                location: masked_location,
                cache_hit: cache_hit,
                cache_enabled: cache_enabled?,
                cache_ttl_seconds: cache_enabled? ? cache_ttl : nil,
                duration_ms: (duration * 1000).round(2),
                project_id: context.project&.id
              )
            end

            def log_http_timeout
              Gitlab::AppJsonLogger.warn(
                class: self.class.name,
                message: 'CI config HTTP request timed out',
                project_id: context.project&.id,
                extra: {
                  location: masked_location,
                  open_timeout_s: http_options[:open_timeout],
                  read_timeout_s: http_options[:read_timeout]
                }
              )
            end

            def verify_integrity(content)
              expected_hash = params[:integrity].delete_prefix('sha256-')
              actual_hash = Base64.strict_encode64(
                Digest::SHA256.digest(content)
              )

              unless Rack::Utils.secure_compare(actual_hash, expected_hash)
                errors.push("Remote file `#{masked_location}` failed integrity check!")
              end
            end
          end
        end
      end
    end
  end
end
