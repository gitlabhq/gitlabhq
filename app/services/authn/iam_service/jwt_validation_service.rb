# frozen_string_literal: true

module Authn
  module IamService
    class JwtValidationService
      InvalidTokenError = Class.new(StandardError)
      InvalidSubjectError = Class.new(InvalidTokenError)

      # Feature flag for gradual rollout, will be used in SessionController
      # TODO: remove this reference upon first usage
      FEATURE_FLAG = :iam_svc_login

      MAX_TOKEN_SIZE_BYTES = 8192
      CLOCK_SKEW_SECONDS = 30
      ALLOWED_ALGORITHM = 'RS256'

      attr_reader :token_string

      def initialize(token:)
        @token_string = token
      end

      def execute
        unless iam_config.enabled
          Gitlab::AuthLogger.info(
            message: 'IAM JWT authentication attempt when disabled',
            reason: :disabled
          )
          return ServiceResponse.error(message: 'IAM JWT authentication is disabled', reason: :disabled)
        end

        jwt_payload = decode_and_validate_token

        ServiceResponse.success(payload: { jwt_payload: jwt_payload })
      rescue JwksClient::JwksFetchFailedError, JwksClient::ConfigurationError => e
        ServiceResponse.error(message: e.message, reason: :service_unavailable)
      rescue InvalidTokenError, JWT::DecodeError => e
        handle_validation_error(jwt_error_to_message(e))
      end

      private

      def decode_and_validate_token
        raise InvalidTokenError, 'Token exceeds maximum size' if token_string.bytesize > MAX_TOKEN_SIZE_BYTES

        payload, _header = JWT.decode(token_string, nil, true, decode_options)

        user_id = payload['sub'].to_i
        raise InvalidSubjectError unless user_id > 0 && user_id.to_s == payload['sub']

        payload
      end

      def decode_options
        {
          algorithms: [ALLOWED_ALGORITHM],
          jwks: jwks_client.keyset,
          required_claims: %w[sub jti exp iat iss aud scope],
          verify_aud: true,
          aud: iam_config.audience,
          exp_leeway: CLOCK_SKEW_SECONDS,
          verify_iss: true,
          iss: iam_config.url,
          verify_iat: true
        }
      end

      def jwt_error_to_message(error)
        case error
        when InvalidSubjectError then 'Invalid token subject'
        when InvalidTokenError then 'Invalid token'
        when JWT::ExpiredSignature then 'Token has expired'
        when JWT::InvalidIatError then 'Invalid token issue time'
        when JWT::InvalidIssuerError then 'Invalid token issuer'
        when JWT::InvalidAudError then 'Invalid token audience'
        when JWT::VerificationError then 'Signature verification failed'
        else 'Invalid token format'
        end
      end

      def handle_validation_error(error_message)
        Gitlab::AuthLogger.error(
          message: 'IAM JWT validation failed',
          error: error_message
        )
        ServiceResponse.error(message: error_message, reason: :invalid_token)
      end

      def iam_config
        Gitlab.config.authn.iam_service
      end

      def jwks_client
        Authn::IamService::JwksClient.new
      end
    end
  end
end
