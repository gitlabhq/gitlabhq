# frozen_string_literal: true

module Ci
  module Runners
    class ResetRegistrationTokenService
      # @param [ApplicationSetting, Project, Group] scope: the scope of the reset operation
      # @param [User] user: the user performing the operation
      def initialize(scope, user)
        @scope = scope
        @user = user
      end

      def execute
        return unless @user.present? && @user.can?(:update_runners_registration_token, scope)

        case scope
        when ::ApplicationSetting
          scope.reset_runners_registration_token!
          ApplicationSetting.current_without_cache.runners_registration_token
        when ::Group, ::Project
          scope.reset_runners_token!
          scope.runners_token
        end
      end

      private

      attr_reader :scope, :user
    end
  end
end
