# frozen_string_literal: true

module QA
  module Support
    module API
      extend self

      HTTP_STATUS_OK = 200
      HTTP_STATUS_CREATED = 201
      HTTP_STATUS_NO_CONTENT = 204
      HTTP_STATUS_ACCEPTED = 202
      HTTP_STATUS_PERMANENT_REDIRECT = 308
      HTTP_STATUS_NOT_FOUND = 404
      HTTP_STATUS_TOO_MANY_REQUESTS = 429
      HTTP_STATUS_SERVER_ERROR = 500

      def post(url, payload, args = {})
        with_retry_on_too_many_requests do
          default_args = {
            method: :post,
            url: url,
            payload: payload,
            verify_ssl: false
          }

          RestClient::Request.execute(default_args.merge(with_canary(args)))
        rescue StandardError => e
          return_response_or_raise(e)
        end
      end

      def get(url, args = {})
        with_retry_on_too_many_requests do
          default_args = {
            method: :get,
            url: url,
            verify_ssl: false
          }

          RestClient::Request.execute(default_args.merge(with_canary(args)))
        rescue StandardError => e
          return_response_or_raise(e)
        end
      end

      def patch(url, payload = nil, args = {})
        with_retry_on_too_many_requests do
          default_args = {
            method: :patch,
            url: url,
            payload: payload,
            verify_ssl: false
          }

          RestClient::Request.execute(default_args.merge(with_canary(args)))
        rescue StandardError => e
          return_response_or_raise(e)
        end
      end

      def put(url, payload = nil, args = {})
        with_retry_on_too_many_requests do
          default_args = {
            method: :put,
            url: url,
            payload: payload,
            verify_ssl: false
          }

          RestClient::Request.execute(default_args.merge(with_canary(args)))
        rescue StandardError => e
          return_response_or_raise(e)
        end
      end

      def delete(url)
        with_retry_on_too_many_requests do
          RestClient::Request.execute(
            method: :delete,
            url: url,
            verify_ssl: false)
        rescue StandardError => e
          return_response_or_raise(e)
        end
      end

      def head(url)
        with_retry_on_too_many_requests do
          RestClient::Request.execute(
            method: :head,
            url: url,
            verify_ssl: false)
        rescue StandardError => e
          return_response_or_raise(e)
        end
      end

      def masked_url(url)
        url.sub(/private_token=[^&]*/, "private_token=[****]")
      end

      # Merges the gitlab_canary cookie into existing cookies for mixed environment testing.
      #
      # @param [Hash] args the existing args passed to method
      # @return [Hash] args or args with merged canary cookie if it exists
      def with_canary(args)
        args.deep_merge(cookies: QA::Runtime::Env.canary_cookie)
      end

      def with_retry_on_too_many_requests
        response = nil

        Support::Retrier.retry_until(log: false) do
          response = yield

          if response.code == HTTP_STATUS_TOO_MANY_REQUESTS
            wait_seconds = response.headers[:retry_after].to_i
            QA::Runtime::Logger.debug("Received 429 - Too many requests. Waiting for #{wait_seconds} seconds.")

            sleep wait_seconds
          end

          response.code != HTTP_STATUS_TOO_MANY_REQUESTS
        end

        response
      end

      def parse_body(response)
        JSON.parse(response.body, symbolize_names: true)
      end

      def return_response_or_raise(error)
        raise error, masked_url(error.to_s) unless error.respond_to?(:response) && error.response

        error.response
      end

      def auto_paginated_response(url, attempts: 0)
        pages = []
        with_paginated_response_body(url, attempts: attempts) { |response| pages << response }

        pages.flatten
      end

      def with_paginated_response_body(url, attempts: 0)
        not_ok_error = ->(resp) do
          raise "Failed to GET #{masked_url(url)} - (#{resp.code}): `#{resp}`."
        end

        loop do
          response = if attempts > 0
                       Retrier.retry_on_exception(max_attempts: attempts, log: false) do
                         get(url).tap { |resp| not_ok_error.call(resp) if resp.code != HTTP_STATUS_OK }
                       end
                     else
                       get(url).tap { |resp| not_ok_error.call(resp) if resp.code != HTTP_STATUS_OK }
                     end

          page, pages, next_page = response.headers.values_at(:x_page, :x_total_pages, :x_next_page)
          api_endpoint = url.match(%r{v4/(\S+)\?})[1]

          QA::Runtime::Logger.debug("Fetching page (#{page}/#{pages}) for '#{api_endpoint}' ...") unless pages.to_i <= 1

          yield parse_body(response)

          break if next_page.blank?

          url = url.match?(/&page=\d+/) ? url.gsub(/&page=\d+/, "&page=#{next_page}") : "#{url}&page=#{next_page}"
        end
      end
    end
  end
end
