# frozen_string_literal: true

module Import
  module UserMapping
    class AdminBypassAuthorizer
      def initialize(reassigning_user)
        @reassigning_user = reassigning_user
      end

      def allowed?
        return false unless reassigning_user

        ::Gitlab::CurrentSettings.allow_bypass_placeholder_confirmation &&
          reassigning_user.can_admin_all_resources? &&
          Gitlab.config.gitlab.impersonation_enabled
      end

      private

      attr_reader :reassigning_user
    end
  end
end
