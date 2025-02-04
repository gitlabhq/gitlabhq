# frozen_string_literal: true

module Ci
  module Runners
    class ResetAuthenticationTokenService
      attr_reader :runner, :current_user

      def initialize(runner:, current_user:)
        @runner = runner
        @current_user = current_user
      end

      def execute
        unless current_user&.can?(:update_runner, runner)
          return ServiceResponse.error(message: 'user is not allowed to reset runner authentication token')
        end

        return ServiceResponse.success if runner.reset_token!

        ServiceResponse.error(message: "Couldn't reset token")
      end
    end
  end
end
