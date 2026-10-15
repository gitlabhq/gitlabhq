# frozen_string_literal: true

module Terraform
  module States
    class RestoreService
      def initialize(state, current_user:)
        @state = state
        @current_user = current_user
      end

      def execute
        return unauthorized_response unless can_restore_state?
        return not_deleted_response unless state.deleted_at?
        return grace_period_expired_response if state.deleted_at <= Terraform::State::GRACE_PERIOD.ago

        state.update!(deleted_at: nil)
        log_event
        ServiceResponse.success(payload: { terraform_state: state })
      end

      private

      attr_reader :state, :current_user

      def can_restore_state?
        current_user.can?(:restore_terraform_state, state.project)
      end

      def unauthorized_response
        error_response(s_('Terraform|You have insufficient permissions to restore this state'))
      end

      def not_deleted_response
        error_response(s_('Terraform|State is not marked for deletion'))
      end

      def grace_period_expired_response
        error_response(s_('Terraform|Grace period for this state has elapsed'))
      end

      def error_response(message)
        ServiceResponse.error(message: message)
      end

      def log_event
        Gitlab::AppLogger.info("User #{current_user.id} restored Terraform state #{state.id}")
      end
    end
  end
end
Terraform::States::RestoreService.prepend_mod
