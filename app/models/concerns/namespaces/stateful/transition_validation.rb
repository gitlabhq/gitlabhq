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
        if Feature.enabled?(:namespace_state_propagation, self)
          validate_parent_state(transition)
        else
          validate_ancestor_chain_state(transition)
        end
      end

      def validate_parent_state(transition)
        return true if parent.nil?

        forbidden_states = FORBIDDEN_ANCESTOR_STATES[transition.event]
        return true if forbidden_states.blank?
        return true unless forbidden_states.include?(parent.state_name)

        add_forbidden_state_error(parent)

        false
      end

      def validate_ancestor_chain_state(transition)
        return true if ancestors.empty?

        forbidden_states = FORBIDDEN_ANCESTOR_STATES[transition.event]
        return true if forbidden_states.blank?

        state_values = forbidden_states.map { |s| self.class.states[s] }
        ancestor_in_forbidden_state = ancestors.where(state: state_values).first
        return true unless ancestor_in_forbidden_state

        add_forbidden_state_error(ancestor_in_forbidden_state)

        false
      end

      def add_forbidden_state_error(namespace)
        errors.add(
          :state,
          format(
            "cannot be changed as ancestor ID %{id} is %{state_name}",
            id: namespace.id,
            state_name: namespace.state_name
          )
        )
      end
    end
  end
end
