# frozen_string_literal: true

module Authn
  module Iam
    class AuthenticationService
      def initialize(token)
        @token = token
      end

      def execute
        return error_feature_disabled unless feature_enabled_for_user?(user_id)

        # Placeholder for actual authentication logic
        # Will be implemented in follow-up MR
        error_not_implemented
      end

      private

      attr_reader :token

      def user_id
        # Placeholder - will extract from JWT in follow-up MR
        nil
      end

      # WORKAROUND: Check user-scoped feature flag for gradual production rollout
      # This is temporary - allows testing IAM JWT with specific users in production
      # without impacting all users. The user lookup here is acceptable because:
      # 1. It only happens for valid IAM JWTs (after signature verification)
      # 2. It fails fast before creating token object
      # 3. It's a temporary workaround for safe production testing
      # TODO: Remove this method once IAM JWT is fully rolled out
      def feature_enabled_for_user?(user_id)
        return false unless user_id

        user = User.find_by(id: user_id) # rubocop:disable CodeReuse/ActiveRecord -- Temporary workaround for safe production testing
        return false unless user

        Feature.enabled?(:iam_svc_oauth, user)
      end

      def error_feature_disabled
        { status: :error, message: 'IAM Service authentication is not enabled' }
      end

      def error_not_implemented
        { status: :error, message: 'IAM Service authentication not yet implemented' }
      end
    end
  end
end
