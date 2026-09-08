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

      class << self
        # Primary public interface for creating validated tokens.
        def from_jwt(token_string)
          return unless Authn::IamAuthService.enabled?

          jwt = strip_access_token_prefix(token_string)
          return unless jwt

          result = ::Authn::IamService::JwtValidationService.new(token: jwt).execute
          return unless result.success?

          token = from_validated_jwt(result.payload)

          # Check user-scoped feature flag for gradual production rollout
          return unless token&.user
          return unless Feature.enabled?(:iam_svc_oauth, token.user)

          token
        end

        private

        # Cheap prefix check before expensive JWT validation.
        def strip_access_token_prefix(token_string)
          return unless token_string.is_a?(String) && token_string.start_with?(ACCESS_TOKEN_PREFIX)

          token_string.delete_prefix(ACCESS_TOKEN_PREFIX)
        end

        def from_validated_jwt(validated_data)
          jwt_payload = validated_data[:jwt_payload]

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
