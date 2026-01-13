# frozen_string_literal: true

module Namespaces
  module Stateful
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
        state_metadata.merge!(
          deletion_scheduled_at: Time.current.as_json,
          deletion_scheduled_by_user_id: transition_user(transition).id
        )
      end

      def clear_deletion_schedule_data(_transition)
        state_metadata.except!('deletion_scheduled_at', 'deletion_scheduled_by_user_id')
      end

      def update_state_metadata_on_failure(transition)
        error_message = build_transition_error_message(transition)
        update_state_metadata(transition, error: error_message)
        namespace_details.save!
      end

      def build_transition_error_message(transition)
        base_message = "Cannot transition from #{transition.from_name} to #{transition.to_name} via #{transition.event}"

        reasons = []
        reasons << errors[:state].join(', ') if errors[:state].present?

        reasons.any? ? "#{base_message}: #{reasons.join('; ')}" : "#{base_message}: unknown reason"
      end
    end
  end
end
