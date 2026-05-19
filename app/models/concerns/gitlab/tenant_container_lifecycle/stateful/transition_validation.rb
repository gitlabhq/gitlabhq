# frozen_string_literal: true

module Gitlab
  module TenantContainerLifecycle
    module Stateful
      # Shared state machine transition validation.
      # Shared between Namespaces::Stateful and Organizations::Stateful.
      module TransitionValidation
        private

        def ensure_transition_user(transition)
          return true if transition_user(transition)

          errors.add(:state, "#{transition.event} transition needs transition_user")
          false
        end
      end
    end
  end
end
