# frozen_string_literal: true

module Gitlab
  module Auth
    module Otp
      module Strategies
        module FortiAuthenticator
          class ManualOtp < Base
            def validate(otp_code)
              @otp_code = otp_code

              response = Gitlab::HTTP.post(
                auth_url,
                headers: { 'Content-Type': 'application/json' },
                body: body.to_json,
                basic_auth: api_credentials)

              # Successful authentication results in HTTP 200: OK
              # Manual OTP - https://docs.fortinet.com/document/fortiauthenticator/6.2.0/rest-api-solution-guide/704555/authentication-auth
              response.ok? ? success : error_from_response(response)
            rescue StandardError => ex
              Gitlab::AppLogger.error(ex)
              error(ex.message)
            end

            private

            def auth_url
              host = ::Gitlab.config.forti_authenticator.host
              port = ::Gitlab.config.forti_authenticator.port
              path = 'api/v1/auth/'

              "https://#{host}:#{port}/#{path}"
            end

            def body
              { username: user.username,
                token_code: @otp_code }
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
