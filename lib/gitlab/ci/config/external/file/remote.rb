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
              fetch_with_error_handling do
                if fetch_async_content
                  fetch_async_content.value
                else
                  fetch_sync_content
                end
              end
            end
            strong_memoize_attr :content

            def metadata
              super.merge(
                type: :remote,
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

            def fetch_async_content
              return if ::Feature.disabled?(:ci_parallel_remote_includes, context.project)

              # It starts fetching the remote content in a separate thread and returns a lazy_response immediately.
              Gitlab::HTTP.get(location, async: true).tap do |lazy_response|
                context.execute_remote_parallel_request(lazy_response)
              end
            end
            strong_memoize_attr :fetch_async_content

            def fetch_sync_content
              context.logger.instrument(:config_file_fetch_remote_content) do
                Gitlab::HTTP.get(location)
              end
            end

            def fetch_with_error_handling
              begin
                response = yield
              rescue SocketError
                errors.push("Remote file `#{masked_location}` could not be fetched because of a socket error!")
              rescue Timeout::Error
                errors.push("Remote file `#{masked_location}` could not be fetched because of a timeout error!")
              rescue Gitlab::HTTP::Error
                errors.push("Remote file `#{masked_location}` could not be fetched because of HTTP error!")
              rescue Errno::ECONNREFUSED, Gitlab::HTTP::BlockedUrlError => e
                errors.push("Remote file could not be fetched because #{e}!")
              end

              if response&.code.to_i >= 400
                errors.push("Remote file `#{masked_location}` could not be fetched because of HTTP code `#{response.code}` error!")
              end

              response.body if errors.none?
            end
          end
        end
      end
    end
  end
end
