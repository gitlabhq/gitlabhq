# frozen_string_literal: true

module Namespaces
  module Stateful
    # Utility methods for extracting data from transitions
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
