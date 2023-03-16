# frozen_string_literal: true

module Gitlab
  module Auth
    module Otp
      module Strategies
        module DuoAuth
          class ManualOtp < Base
            include Gitlab::Utils::StrongMemoize

            def validate(otp_code)
              params = { username: user.username, factor: "passcode", passcode: otp_code.to_i }
              response = duo_client.request('POST', "/auth/v2/auth", params)
              approve_or_deny(parse_response(response))
            rescue StandardError => e
              Gitlab::AppLogger.error(e)
              error(e.message)
            end

            private

            def duo_client
              DuoApi.new(::Gitlab.config.duo_auth.integration_key,
                ::Gitlab.config.duo_auth.secret_key,
                ::Gitlab.config.duo_auth.hostname)
            end
            strong_memoize_attr :duo_client

            def parse_response(response)
              Gitlab::Json.parse(response.body)
            end

            def approve_or_deny(parsed_response)
              result_key = parsed_response.dig('response', 'result')
              if result_key.to_s == "allow"
                success
              else
                error(message: parsed_response.dig('response', 'status_msg').to_s)
              end
            end
          end
        end
      end
    end
  end
end
