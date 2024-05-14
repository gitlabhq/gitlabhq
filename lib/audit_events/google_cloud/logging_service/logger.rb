# frozen_string_literal: true

module AuditEvents
  module GoogleCloud
    module LoggingService
      class Logger
        WRITE_URL = "https://logging.googleapis.com/v2/entries:write"
        SCOPE = "https://www.googleapis.com/auth/logging.write"

        def initialize
          @auth = AuditEvents::GoogleCloud::Authentication.new(scope: SCOPE)
        end

        def log(client_email, private_key, payload)
          access_token = @auth.generate_access_token(client_email, private_key)

          return unless access_token

          headers = build_headers(access_token)

          post(WRITE_URL, body: payload, headers: headers)
        end

        private

        def build_headers(access_token)
          { 'Authorization' => "Bearer #{access_token}", 'Content-Type' => 'application/json' }
        end

        def post(url, body:, headers:)
          Gitlab::HTTP.post(
            url,
            body: body,
            headers: headers
          )
        rescue URI::InvalidURIError => e
          Gitlab::ErrorTracking.log_exception(e)
        rescue *Gitlab::HTTP::HTTP_ERRORS
        end
      end
    end
  end
end
