# frozen_string_literal: true

module Authn
  module IamService
    # Generic RS256 JWT signature/claims verifier, reused by both IAM
    # (Authn::Tokens::IamOauthToken) and Duo Workflow's stateless tokens
    # (Authn::Tokens::StatelessAccessToken). Only verifies the token itself;
    # callers own their own enablement checks, subject-claim parsing, and any
    # object construction from the returned payload.
    class JwtValidationService
      InvalidTokenError = Class.new(StandardError)

      MAX_TOKEN_SIZE_BYTES = 8192
      ALLOWED_ALGORITHM = 'RS256'

      # `jwks` is a zero-arg callable (not a resolved value), so a lazy fetch
      # (e.g. an HTTP call) only happens inside `execute`'s rescue-protected
      # scope, not at construction time.
      def initialize(
        token:, jwks:, issuer:, audience:, required_claims:,
        exp_leeway: 0, verify_iat: false, verify_not_before: false
      )
        @token_string = token
        @jwks = jwks
        @issuer = issuer
        @audience = audience
        @required_claims = required_claims
        @exp_leeway = exp_leeway
        @verify_iat = verify_iat
        @verify_not_before = verify_not_before
      end

      def execute
        jwt_payload = decode_and_validate_token

        ServiceResponse.success(payload: { jwt_payload: jwt_payload })
      rescue JwksClient::JwksFetchFailedError, JwksClient::ConfigurationError,
        Authn::IamAuthService::ConfigurationError => e
        ServiceResponse.error(message: e.message, reason: :service_unavailable)
      rescue InvalidTokenError, JWT::DecodeError => e
        handle_validation_error(jwt_error_to_message(e))
      end

      private

      attr_reader :token_string

      def decode_and_validate_token
        raise InvalidTokenError, 'Token exceeds maximum size' if token_string.bytesize > MAX_TOKEN_SIZE_BYTES

        payload, _header = JWT.decode(token_string, nil, true, decode_options)
        payload
      end

      def decode_options
        {
          algorithms: [ALLOWED_ALGORITHM],
          jwks: @jwks.call,
          required_claims: @required_claims,
          verify_aud: true,
          aud: @audience,
          exp_leeway: @exp_leeway,
          verify_iss: true,
          iss: @issuer,
          verify_iat: @verify_iat,
          verify_expiration: true,
          verify_not_before: @verify_not_before
        }
      end

      def jwt_error_to_message(error)
        case error
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
          message: 'JWT validation failed',
          error: error_message
        )
        ServiceResponse.error(message: error_message, reason: :invalid_token)
      end
    end
  end
end
