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

      DELETION_METADATA_KEYS = %w[
        deletion_attempt_count
        deletion_last_failed_at
      ].freeze

      TRANSFER_ERROR_MAX_LENGTH = 500

      private

      def set_transfer_schedule_data(transition)
        state_metadata.except!('transfer_last_error')
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

      def set_deletion_data(_transition)
        state_metadata.except!(*DELETION_METADATA_KEYS)
        self.deletion_attempt_count = 0
      end

      def clear_deletion_data(_transition)
        state_metadata.except!(*DELETION_METADATA_KEYS)
      end

      def set_deletion_error_data(transition)
        error = transition_args(transition)[:deletion_error]
        self.deletion_error = error if error.present?

        # Only increment the failure counter when an actual destroy attempt
        # failed (signalled by a non-blank deletion_error). Rescheduling
        # without an error (e.g. permission revocation) is not a failure.
        return unless error.present?

        self.deletion_attempt_count = (deletion_attempt_count || 0) + 1
        state_metadata.merge!(deletion_last_failed_at: Time.current.as_json)
      end

      # Runs after the clear_transfer_data* callbacks on :cancel_transfer, which would otherwise
      # wipe the message we are recording here.
      def set_transfer_error_data(transition)
        error = transition_args(transition)[:transfer_error]
        return if error.blank?

        self.transfer_last_error = error.to_s.truncate(TRANSFER_ERROR_MAX_LENGTH)
      end
    end
  end
end
