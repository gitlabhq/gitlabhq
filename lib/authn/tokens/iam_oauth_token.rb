# frozen_string_literal: true

module Authn
  module Tokens
    class IamOauthToken
      include Gitlab::Utils::StrongMemoize
      include Authn::Tokens::Concerns::DoorkeeperCompatible

      # IAM prefixes every access token it mints with this before the JWT
      # (see gitlab-org/auth/iam's auth/oauth/core/token_prefix.go) and
      # strips it before validating; we mirror that here.
      ACCESS_TOKEN_PREFIX = 'gliamat-'

      REQUIRED_CLAIMS = %w[sub jti exp iat iss aud scope].freeze
      CLOCK_SKEW_SECONDS = 30

      class << self
        # Primary public interface for creating validated tokens.
        def from_jwt(token_string)
          unless Authn::IamAuthService.enabled?
            Gitlab::AuthLogger.info(message: 'IAM JWT authentication attempt when disabled')
            return
          end

          jwt = strip_access_token_prefix(token_string)
          return unless jwt

          result = validate_jwt(jwt)
          return unless result.success?

          jwt_payload = result.payload[:jwt_payload]
          return unless valid_subject?(jwt_payload['sub'])

          token = from_validated_jwt(jwt_payload)

          # Check user-scoped feature flag for gradual production rollout
          return unless token&.user
          return unless Feature.enabled?(:iam_svc_oauth, token.user)

          token
        end

        private

        def validate_jwt(jwt)
          ::Authn::IamService::JwtValidationService.new(
            token: jwt,
            jwks: -> { ::Authn::IamService::JwksClient.new.keyset },
            issuer: Authn::IamAuthService.jwt_issuer,
            audience: Authn::IamAuthService.jwt_audience,
            required_claims: REQUIRED_CLAIMS,
            exp_leeway: CLOCK_SKEW_SECONDS,
            verify_iat: true
          ).execute
        end

        def valid_subject?(sub)
          user_id = sub.to_i
          return true if user_id > 0 && user_id.to_s == sub

          Gitlab::AuthLogger.error(
            message: 'IAM JWT validation failed',
            Labkit::Fields::ERROR_MESSAGE => 'Invalid token subject'
          )
          false
        end

        # Cheap prefix check before expensive JWT validation.
        def strip_access_token_prefix(token_string)
          return unless token_string.is_a?(String) && token_string.start_with?(ACCESS_TOKEN_PREFIX)

          token_string.delete_prefix(ACCESS_TOKEN_PREFIX)
        end

        def from_validated_jwt(jwt_payload)
          scopes = extract_scopes(jwt_payload)
          scope_user_id = Authn::ScopedUserExtractor.extract_user_id_from_scopes(scopes)

          new(
            user_id: jwt_payload['sub'].to_i,
            scopes: scopes,
            id: jwt_payload['jti'],
            expires_at: Time.zone.at(jwt_payload['exp']),
            issued_at: Time.zone.at(jwt_payload['iat']),
            scope_user_id: scope_user_id
          )
        end

        def extract_scopes(payload)
          return [] if payload['scope'].blank?

          Array(payload['scope']).flat_map(&:split)
        end
      end

      attr_reader :user_id, :id, :expires_at, :issued_at, :scope_user_id, :raw_scopes

      private_class_method :new

      def initialize(user_id:, scopes:, id:, expires_at:, issued_at:, scope_user_id: nil)
        @user_id = user_id
        @raw_scopes = scopes
        @id = id
        @expires_at = expires_at
        @issued_at = issued_at
        @scope_user_id = scope_user_id
      end

      def reload
        clear_memoization(:user)
        clear_memoization(:scope_user)
        self
      end

      # IAM JWTs are stateless and cannot be revoked individually by default.
      # TODO: Implement JTI-based revocation list to support token invalidation.
      def revoked?
        false
      end

      # Extracted scoped user from 'user:X' scope (for composite identity)
      def scope_user
        return unless scope_user_id

        User.find_by_id(scope_user_id)
      end
      strong_memoize_attr :scope_user

      def to_s
        "Authn::Tokens::IamOauthToken(id: #{id}, user_id: #{user_id})"
      end

      # Lazy load user (follows OAuth token association pattern)
      def user
        User.find_by_id(user_id)
      end
      strong_memoize_attr :user
    end
  end
end
