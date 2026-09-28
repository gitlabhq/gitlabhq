# frozen_string_literal: true

module Mcp
  module Tools
    module Base
      module RateLimitedResponse
        TOO_MANY_REQUESTS = 429
        RETRY_AFTER_HEADER = 'Retry-After'
        RATE_LIMIT_NAME_HEADER = 'RateLimit-Name'

        private

        def rate_limited_response(body, headers)
          ::Mcp::Tools::Base::Response.rate_limited_error(
            throttle_message(body),
            retry_after: header_value(headers, RETRY_AFTER_HEADER),
            limit: header_value(headers, RATE_LIMIT_NAME_HEADER)
          )
        end

        def throttle_message(body)
          parsed_response = ::Gitlab::Json.safe_parse(body)
          message = parsed_response&.[]('error') || parsed_response&.[]('message')
          message = message['error'] if message.is_a?(Hash)
          message.presence || "HTTP #{TOO_MANY_REQUESTS}"
        rescue JSON::ParserError, ::Gitlab::Json::ParserError
          "HTTP #{TOO_MANY_REQUESTS}"
        end

        def header_value(headers, name)
          return if headers.blank?

          Array.wrap(headers.find { |key, _| key.to_s.casecmp?(name) }&.last).first
        end
      end
    end
  end
end
