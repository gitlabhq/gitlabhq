# frozen_string_literal: true

module Gitlab
  module TenantContainerLifecycle
    module Stateful
      # Shared state machine transition logging.
      # Shared between Namespaces::Stateful and Organizations::Stateful.
      #
      # Including classes must implement `stateful_log_metadata` (private) returning a hash
      # with at minimum a `message:` key, e.g.:
      #   { message: 'Namespace state transition', namespace_id: id }
      #
      # Including classes must also implement `stateful_detail` (private) to return
      # the associated detail model (e.g. namespace_details or organization_detail).
      module TransitionLogging
        private

        def log_transition(transition)
          Gitlab::AppLogger.info(
            stateful_log_metadata.merge(
              from_state: transition.from_name,
              to_state: transition.to_name,
              event: transition.event,
              Labkit::Fields::GL_USER_ID => transition_user(transition)&.id
            )
          )
        end

        def log_transition_failure(transition)
          meta = stateful_log_metadata
          Gitlab::AppLogger.error(
            meta.merge(
              message: "#{meta[:message]} failed",
              event: transition.event,
              current_state: state_name,
              error: stateful_detail.state_metadata['last_error'],
              Labkit::Fields::GL_USER_ID => transition_user(transition)&.id
            )
          )
        end

        def stateful_log_metadata
          raise NotImplementedError, "#{self.class}#stateful_log_metadata must be implemented"
        end
      end
    end
  end
end
