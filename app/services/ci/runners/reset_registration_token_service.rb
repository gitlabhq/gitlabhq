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

        if scope.respond_to?(:runners_registration_token)
          scope.reset_runners_registration_token!
          scope.runners_registration_token
        else
          scope.reset_runners_token!
          scope.runners_token
        end
      end

      private

      attr_reader :scope, :user
    end
  end
end

Ci::Runners::ResetRegistrationTokenService.prepend_mod
