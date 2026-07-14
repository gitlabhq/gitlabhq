# frozen_string_literal: true

module Gitlab
  module MailRoom
    class Authenticator
      include JwtAuthenticatable

      SecretConfigurationError = Class.new(StandardError)

      # Only allow token generated within the last 5 minutes
      EXPIRATION = 5.minutes

      # Default signing algorithm used to authenticate requests between the
      # mail_room component and the internal API. Mailboxes that also configure
      # asymmetric public keys accept ES256 tokens (identified by a `kid` header)
      # in addition to this default. See
      # https://gitlab.com/gitlab-org/gitlab/-/work_items/604265
      DEFAULT_ALGORITHM = 'HS256'

      # Algorithm used when a mailbox is configured with asymmetric public keys.
      ASYMMETRIC_ALGORITHM = 'ES256'

      class << self
        def verify_api_request(request_headers, mailbox_type)
          mailbox_type = mailbox_type.to_sym
          return false if enabled_configs[mailbox_type].blank?

          token = request_headers[Gitlab::MailRoom::INTERNAL_API_REQUEST_HEADER]

          options = verification_options(mailbox_type, token)
          return false unless options

          key = options.delete(:key)
          decode_jwt(token, key, **options)
        rescue JWT::DecodeError => e
          log_verification_failure(mailbox_type, e)

          false
        end

        def enabled_configs
          Gitlab::MailRoom.enabled_configs
        end

        private

        # Builds the arguments for decode_jwt based on what the mailbox has
        # configured and, only when both symmetric and asymmetric credentials
        # are present, on whether the token carries a `kid` header.
        #
        # The algorithm is always determined by server-side configuration and
        # the presence of a `kid`, never by the token's `alg` header, which
        # avoids algorithm-confusion attacks. We never attempt both methods for
        # a single request.
        #
        # @return [Hash, nil] decode_jwt options, or nil when the mailbox has no
        #   credentials for the applicable method.
        def verification_options(mailbox_type, token)
          config = MailboxConfig.new(enabled_configs[mailbox_type], mailbox_type)

          if config.symmetric? && config.asymmetric?
            token_has_kid?(token) ? asymmetric_options(config) : symmetric_options(config)
          elsif config.asymmetric?
            asymmetric_options(config)
          elsif config.symmetric?
            symmetric_options(config)
          end
        end

        def symmetric_options(config)
          common_options.merge(
            key: symmetric_secret(config),
            algorithm: DEFAULT_ALGORITHM
          )
        end

        def asymmetric_options(config)
          common_options.merge(
            key: nil,
            algorithm: ASYMMETRIC_ALGORITHM,
            jwks: public_key_set_for(config)
          )
        end

        def common_options
          {
            issuer: Gitlab::MailRoom::INTERNAL_API_REQUEST_JWT_ISSUER,
            iat_after: Time.current - EXPIRATION
          }
        end

        # Reads the `kid` from the token header without verifying the signature.
        # The header is unauthenticated input, so it is only used to decide which
        # verification method to apply, never to select keys or algorithms.
        def token_has_kid?(token)
          _payload, header = JWT.decode(token, nil, false)
          header['kid'].present?
        rescue JWT::DecodeError
          false
        end

        def symmetric_secret(config)
          strong_memoize_with(:jwt_secret, config.mailbox_type) do
            read_secret(config.secret_file)
          rescue StandardError => e
            raise SecretConfigurationError, "Failed to read #{config.mailbox_type}'s secret: #{e.message}"
          end
        end

        def public_key_set_for(config)
          strong_memoize_with(:jwt_public_key_set, config.mailbox_type) do
            public_key_set(config.public_key_files)
          rescue StandardError => e
            raise SecretConfigurationError, "Failed to read #{config.mailbox_type}'s public keys: #{e.message}"
          end
        end

        # Logs the failure type but not the error message: JWT::DecodeError
        # messages reveal why verification failed (bad signature, expired,
        # malformed), which an attacker with access to a compromised cell's logs
        # could use to tune forgery attempts against other cells.
        def log_verification_failure(mailbox_type, error)
          ::Gitlab::AppLogger.warn(
            Labkit::Fields::LOG_MESSAGE => "Failed to decode MailRoom JWT token for #{mailbox_type} mailbox",
            Labkit::Fields::CLASS_NAME => name,
            Labkit::Fields::ERROR_TYPE => error.class.name
          )
        end
      end
    end
  end
end
