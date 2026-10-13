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

        # Deferred with the worker enqueue so a rolled-back outer transaction
        # does not leave a phantom deletion event in the analytics pipeline.
        # `with_versions` distinguishes throwaway `terraform init` artifacts.
        user = current_user
        category = self.class.name
        label = state.versions.exists? ? 'with_versions' : 'without_versions'

        state.run_after_commit do
          Terraform::States::DestroyWorker.perform_async(id)

          Gitlab::InternalEvents.track_event(
            'delete_terraform_state',
            category: category,
            project: project,
            user: user,
            additional_properties: { label: label }
          )
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
