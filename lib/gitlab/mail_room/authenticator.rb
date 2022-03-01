# frozen_string_literal: true

module Gitlab
  module MailRoom
    class Authenticator
      include JwtAuthenticatable

      SecretConfigurationError = Class.new(StandardError)

      # Only allow token generated within the last 5 minutes
      EXPIRATION = 5.minutes

      class << self
        def verify_api_request(request_headers, mailbox_type)
          mailbox_type = mailbox_type.to_sym
          return false if enabled_configs[mailbox_type].blank?

          decode_jwt(
            request_headers[Gitlab::MailRoom::INTERNAL_API_REQUEST_HEADER],
            secret(mailbox_type),
            issuer: Gitlab::MailRoom::INTERNAL_API_REQUEST_JWT_ISSUER,
            iat_after: Time.current - EXPIRATION
          )
        rescue JWT::DecodeError => e
          ::Gitlab::AppLogger.warn("Fail to decode MailRoom JWT token: #{e.message}") if Rails.env.development?

          false
        end

        def secret(mailbox_type)
          strong_memoize("jwt_secret_#{mailbox_type}".to_sym) do
            secret_path = enabled_configs[mailbox_type][:secret_file]
            raise SecretConfigurationError, "#{mailbox_type}'s secret_file configuration is missing" if secret_path.blank?

            begin
              read_secret(secret_path)
            rescue StandardError => e
              raise SecretConfigurationError, "Fail to read #{mailbox_type}'s secret: #{e.message}"
            end
          end
        end

        def enabled_configs
          Gitlab::MailRoom.enabled_configs
        end
      end
    end
  end
end
