# frozen_string_literal: true

module Namespaces
  module Stateful
    module TransitionValidation
      include ::Gitlab::TenantContainerLifecycle::Stateful::TransitionValidation

      FORBIDDEN_ANCESTOR_STATES = {
        archive: %i[archived deletion_in_progress deletion_scheduled],
        unarchive: %i[deletion_in_progress deletion_scheduled],
        schedule_deletion: %i[deletion_in_progress deletion_scheduled]
      }.freeze

      private

      def validate_ancestors_state(transition)
        return true if ancestors.empty?

        forbidden_states = FORBIDDEN_ANCESTOR_STATES[transition.event]
        return true if forbidden_states.blank?

        state_values = forbidden_states.map { |s| self.class.states[s] }
        ancestor_in_forbidden_state = ancestors.where(state: state_values).first
        return true unless ancestor_in_forbidden_state

        errors.add(
          :state,
          format(
            "cannot be changed as ancestor ID %{id} is %{state_name}",
            id: ancestor_in_forbidden_state.id,
            state_name: ancestor_in_forbidden_state.state_name
          )
        )

        false
      end
    end
  end
end
