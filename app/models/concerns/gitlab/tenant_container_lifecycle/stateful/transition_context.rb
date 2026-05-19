# frozen_string_literal: true

module Gitlab
  module TenantContainerLifecycle
    module Stateful
      # Utility methods for extracting data from state machine transitions.
      # Shared between Namespaces::Stateful and Organizations::Stateful.
      module TransitionContext
        private

        def transition_args(transition)
          transition.args.first || {}
        end

        def transition_user(transition)
          transition_args(transition)[:transition_user]
        end
      end
    end
  end
end
