# frozen_string_literal: true

module Authn
  module IamService
    class JwtValidationService
      CLOCK_SKEW_SECONDS = 30
      ALLOWED_ALGORITHMS = ['RS256'].freeze
      GITLAB_RAILS_AUDIENCE = Gitlab.config.authn.iam_service.audience
      IAM_AUTH_CLIENT_HANDLER_AUDIENCE = 'iam-auth-client-handler'

      class IamAuthClientPayloadValidator
        REQUIRED_CLAIMS = %w[exp aud provider user_info].freeze
      end

      class IamIdToken
        REQUIRED_CLAIMS = %w[sub jti exp iat iss aud scope].freeze
      end

      VALIDATORS = {
        GITLAB_RAILS_AUDIENCE => IamIdToken,
        IAM_AUTH_CLIENT_HANDLER_AUDIENCE => IamAuthClientPayloadValidator
      }.freeze

      attr_reader :token_string, :expected_audience, :validator

      def initialize(token:, audience:)
        @token_string = token
        @expected_audience = audience
        @retry_attempted = false
        @validator = VALIDATORS.fetch(audience)
      end

      def execute
        unless iam_config.enabled
          return ServiceResponse.error(message: 'IAM JWT authentication is disabled', reason: :disabled)
        end

        jwt_payload = decode_with_retry

        ServiceResponse.success(payload: { jwt_payload: jwt_payload })
      rescue JwksClient::JwksFetchFailedError, JwksClient::ConfigurationError => e
        ServiceResponse.error(message: e.message, reason: :service_unavailable)
      rescue JWT::DecodeError => e
        handle_validation_error(jwt_error_to_message(e))
      end

      private

      # TODO: Potential DoS vector - refresh_keys is called for ANY verification failure, not just key rotation.
      # Explore using ruby-jwt's jwks lambda with `kid_not_found` option to refresh only when kid is missing.
      def decode_with_retry
        decode_token
      rescue JWT::VerificationError
        raise if @retry_attempted

        @retry_attempted = true
        jwks_client.refresh_keys
        decode_token
      end

      def decode_token
        payload, _ = JWT.decode(token_string, nil, true, decode_options)
        payload
      end

      # TODO: agree and implement validation on jti to prevent the JWT from being replayed
      def decode_options
        {
          algorithms: ALLOWED_ALGORITHMS,
          jwks: jwks_client.fetch_keys,
          required_claims: validator::REQUIRED_CLAIMS,
          verify_iss: true,
          iss: iam_config.url,
          verify_aud: true,
          aud: expected_audience,
          verify_iat: true,
          verify_exp: true,
          leeway: CLOCK_SKEW_SECONDS
        }
      end

      def jwt_error_to_message(error)
        case error
        when JWT::ExpiredSignature then 'Token has expired'
        when JWT::InvalidIatError then 'Invalid token issue time'
        when JWT::InvalidIssuerError then 'Invalid token issuer'
        when JWT::InvalidAudError then 'Invalid token audience'
        when JWT::VerificationError then "Signature verification failed: #{error.message}"
        else "Invalid token format: #{error.message}"
        end
      end

      def handle_validation_error(error_message)
        Gitlab::AuthLogger.warn(
          message: 'IAM JWT validation failed',
          error_message: error_message
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
