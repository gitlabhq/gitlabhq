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
        unless @user.present? && @user.can?(:update_runners_registration_token, scope)
          return ServiceResponse.error(message: 'user not allowed to update runners registration token')
        end

        if scope.respond_to?(:runners_registration_token)
          scope.reset_runners_registration_token!
          runners_token = scope.runners_registration_token
        else
          scope.reset_runners_token!
          runners_token = scope.runners_token
        end

        ServiceResponse.success(payload: { new_registration_token: runners_token })
      end

      private

      attr_reader :scope, :user
    end
  end
end

Ci::Runners::ResetRegistrationTokenService.prepend_mod
