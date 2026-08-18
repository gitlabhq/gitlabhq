# frozen_string_literal: true

module Namespaces
  module Stateful
    module TransitionCallbacks
      include ::Gitlab::TenantContainerLifecycle::Stateful::TransitionCallbacks

      TRANSFER_METADATA_KEYS = %w[
        transfer_scheduled_at
        transfer_scheduled_by_user_id
        transfer_initiated_at
        transfer_initiated_by_user_id
        transfer_target_parent_id
        transfer_attempt_count
        transfer_last_error
      ].freeze

      private

      def set_transfer_schedule_data(transition)
        state_metadata.merge!(
          transfer_scheduled_at: Time.current.as_json,
          transfer_scheduled_by_user_id: transition_user(transition).id
        )
      end

      def set_transfer_data(transition)
        state_metadata.merge!(
          transfer_initiated_at: Time.current.as_json,
          transfer_initiated_by_user_id: transition_user(transition).id,
          transfer_attempt_count: 0
        )
      end

      def clear_transfer_data(_transition)
        state_metadata.except!(*TRANSFER_METADATA_KEYS)
      end

      def clear_transfer_data_preserving_target(_transition)
        state_metadata.except!(*(TRANSFER_METADATA_KEYS - ['transfer_target_parent_id']))
      end
    end
  end
end
