# frozen_string_literal: true

module Namespaces
  module Stateful
    module TransitionLogging
      private

      def log_transition(transition)
        Gitlab::AppLogger.info(
          message: 'Namespace state transition',
          namespace_id: id,
          from_state: transition.from_name,
          to_state: transition.to_name,
          event: transition.event,
          user_id: transition_user(transition)&.id
        )
      end

      def log_transition_failure(transition)
        Gitlab::AppLogger.error(
          message: 'Namespace state transition failed',
          namespace_id: id,
          event: transition.event,
          current_state: state_name,
          error: state_metadata['last_error'],
          user_id: transition_user(transition)&.id
        )
      end
    end
  end
end
