# frozen_string_literal: true

module Gitlab
  module Auth
    module Otp
      module Strategies
        module FortiAuthenticator
          class PushOtp < Base
            def validate
              response = Gitlab::HTTP.post(
                auth_url,
                headers: { 'Content-Type': 'application/json' },
                body: body.to_json,
                basic_auth: api_credentials)

              # Successful authentication results in HTTP 200: OK
              # Push - https://docs.fortinet.com/document/fortiauthenticator/6.2.1/rest-api-solution-guide/943094/push-authentication-pushauth
              response.ok? ? success : error_from_response(response)
            rescue StandardError => ex
              Gitlab::AppLogger.error(ex)
              error(ex.message)
            end

            private

            def auth_url
              host = ::Gitlab.config.forti_authenticator.host
              port = ::Gitlab.config.forti_authenticator.port
              path = 'api/v1/pushauth/'

              "https://#{host}:#{port}/#{path}"
            end

            def body
              { username: user.username }
            end

            def api_credentials
              { username: ::Gitlab.config.forti_authenticator.username,
                password: ::Gitlab.config.forti_authenticator.access_token }
            end
          end
        end
      end
    end
  end
end
