# frozen_string_literal: true

module Authn
  module Tokens
    class IamOauthToken
      include Gitlab::Utils::StrongMemoize

      class << self
        # Primary public interface for creating validated tokens.
        def from_jwt(token_string)
          return unless Gitlab.config.authn.iam_service.enabled
          return unless iam_issued_jwt?(token_string)

          result = ::Authn::IamService::JwtValidationService.new(token: token_string,
            audience: Authn::IamService::JwtValidationService::GITLAB_RAILS_AUDIENCE).execute
          return unless result.success?

          token = from_validated_jwt(result.payload)

          # Check user-scoped feature flag for gradual production rollout
          return unless token&.user
          return unless Feature.enabled?(:iam_svc_oauth, token.user)

          token
        end

        private

        # Checks if a token string is likely an IAM-issued JWT based on format.
        # This is a lightweight check before expensive JWT validation.
        # TODO: Replace with proper token prefix (e.g., 'gliat-') before production
        def iam_issued_jwt?(token_string)
          token_string.is_a?(String) &&
            token_string.start_with?('ey') &&
            token_string.count('.') == 2
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

      attr_reader :user_id, :scopes, :id, :expires_at, :issued_at, :scope_user_id

      private_class_method :new

      def initialize(user_id:, scopes:, id:, expires_at:, issued_at:, scope_user_id: nil)
        @user_id = user_id
        @scopes = scopes
        @id = id
        @expires_at = expires_at
        @issued_at = issued_at
        @scope_user_id = scope_user_id
      end

      def active?
        !expired? && !revoked?
      end

      def expired?
        expires_at.present? && expires_at.past?
      end

      def reload
        clear_memoization(:user)
        clear_memoization(:scope_user)
        self
      end

      # For compatibility with AccessTokenValidationService
      def resource_owner_id
        user_id
      end

      # IAM JWTs are stateless and cannot be revoked individually by default.
      # TODO: Implement JTI-based revocation list to support token invalidation.
      def revoked?
        false
      end

      # For compatibility with Doorkeeper
      # Provided by doorkeeper/models/concerns/accessible.rb
      def accessible?
        active?
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
