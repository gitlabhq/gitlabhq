# frozen_string_literal: true

module Terraform
  module States
    class TriggerDestroyService
      def initialize(state, current_user:)
        @state = state
        @current_user = current_user
      end

      def execute
        return unauthorized_response unless can_destroy_state?
        return state_locked_response if state.locked?

        state.run_after_commit do
          Terraform::States::DestroyWorker.perform_async(id)
        end

        state.update!(deleted_at: Time.current)

        ServiceResponse.success
      end

      private

      attr_reader :state, :current_user

      def can_destroy_state?
        current_user.can?(:admin_terraform_state, state.project)
      end

      def unauthorized_response
        error_response(s_('Terraform|You have insufficient permissions to delete this state'))
      end

      def state_locked_response
        error_response(s_('Terraform|Cannot remove a locked state'))
      end

      def error_response(message)
        ServiceResponse.error(message: message)
      end
    end
  end
end
