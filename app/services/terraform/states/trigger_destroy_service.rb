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

        # `with_versions` distinguishes throwaway `terraform init` artifacts.
        user = current_user
        category = self.class.name
        label = state.versions.exists? ? 'with_versions' : 'without_versions'

        delayed_deletion = Feature.enabled?(:terraform_state_delayed_deletion, state.project)

        if delayed_deletion && state.versions.none?
          # No versions: destroy immediately. run_after_commit fires after destroy! commits.
          state.run_after_commit do
            Gitlab::InternalEvents.track_event(
              'delete_terraform_state',
              category: category,
              project: project,
              user: user,
              additional_properties: { label: label }
            )
          end
          state.destroy!
        else
          state.run_after_commit do
            Terraform::States::DestroyWorker.perform_async(id) unless delayed_deletion

            Gitlab::InternalEvents.track_event(
              'delete_terraform_state',
              category: category,
              project: project,
              user: user,
              additional_properties: { label: label }
            )
          end

          state.update!(deleted_at: Time.current)
        end

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
