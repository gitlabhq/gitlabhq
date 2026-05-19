# frozen_string_literal: true

module Gitlab
  module TenantContainerLifecycle
    module Stateful
      # Shared deletion-related state machine callbacks.
      # Shared between Namespaces::Stateful and Organizations::Stateful.
      #
      # Including classes must implement `stateful_detail` (private) to return
      # the associated detail model (e.g. namespace_details or organization_detail).
      module TransitionCallbacks
        private

        def update_state_metadata(transition, error: nil)
          state_metadata.merge!(
            last_updated_at: Time.current.as_json,
            last_error: error,
            last_changed_by_user_id: transition_user(transition)&.id
          )
        end

        def set_deletion_schedule_data(transition)
          self.deletion_scheduled_at = Time.current
          state_metadata.merge!(
            deletion_scheduled_by_user_id: transition_user(transition).id
          )
        end

        def clear_deletion_schedule_data(_transition)
          self.deletion_scheduled_at = nil
          state_metadata.except!('deletion_scheduled_by_user_id')
        end

        def set_deletion_error_data(transition)
          error = transition_args(transition)[:deletion_error]
          self.deletion_error = error if error.present?
        end

        def update_state_metadata_on_failure(transition)
          error_message = build_transition_error_message(transition)
          update_state_metadata(transition, error: error_message)
          stateful_detail.save!
        end

        def build_transition_error_message(transition)
          base_message =
            "Cannot transition from #{transition.from_name} to #{transition.to_name} via #{transition.event}"

          reasons = []
          reasons << errors[:state].join(', ') if errors[:state].present?

          reasons.any? ? "#{base_message}: #{reasons.join('; ')}" : "#{base_message}: unknown reason"
        end

        def stateful_detail
          raise NotImplementedError, "#{self.class}#stateful_detail must be implemented"
        end
      end
    end
  end
end
