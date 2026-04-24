# frozen_string_literal: true

module Import
  module SourceUsers
    class RetryFailedReassignmentService < BaseService
      include ActionView::Helpers::DateHelper
      include Gitlab::Utils::StrongMemoize

      RETRY_ATTEMPTS_KEY = 'import_source_users/%{source_user_id}/retry_reassignment_timestamps'
      MAX_RETRY_ATTEMPTS = 3
      RETRY_COOLDOWN = 16.hours

      def initialize(import_source_user, current_user:)
        @import_source_user = import_source_user
        @current_user = current_user
      end

      def execute
        return error_invalid_permissions unless current_user.can?(:admin_import_source_user, import_source_user)

        retry_attempts_exceeded = retry_attempts_exceeded?
        invalid_status = false
        retry_successful = false

        import_source_user.with_lock do
          next invalid_status = true unless import_source_user.failed?
          next if retry_attempts_exceeded

          retry_successful = import_source_user.retry_reassignment
        end

        return error_invalid_status if invalid_status
        return error_retry_attempts_exceeded if retry_attempts_exceeded

        if retry_successful
          record_retry_attempt
          Import::ReassignPlaceholderUserRecordsWorker.perform_async(import_source_user.id)
          track_reassignment_event('retry_failed_placeholder_user_reassignment')

          ServiceResponse.success(payload: import_source_user)
        else
          ServiceResponse.error(payload: import_source_user, message: import_source_user.errors.full_messages)
        end
      end

      private

      # Recent retry attempt timestamps as integers sorted in ascending order (oldest to newest)
      def recent_retry_attempts
        Gitlab::Cache::Import::Caching
          .values_from_set(retry_timestamps_key)
          .map(&:to_i)
          .select { |attempt| attempt > RETRY_COOLDOWN.ago.to_i }
          .sort
      end
      strong_memoize_attr :recent_retry_attempts

      def retry_attempts_exceeded?
        recent_retry_attempts.size >= MAX_RETRY_ATTEMPTS
      end

      def record_retry_attempt
        Gitlab::Cache::Import::Caching.set_add(
          retry_timestamps_key,
          Time.current.to_i,
          timeout: RETRY_COOLDOWN
        )
      end

      def retry_timestamps_key
        format(RETRY_ATTEMPTS_KEY, source_user_id: import_source_user.id)
      end

      def error_retry_attempts_exceeded
        earliest_retry_seconds_ago = Time.current - Time.zone.at(recent_retry_attempts.first)
        seconds_remaining = RETRY_COOLDOWN.to_i - earliest_retry_seconds_ago

        message = format(
          s_(
            "Import|Reassignment retry has failed multiple times. " \
              "Repeated failures suggest an unexpected error that may need time to resolve. " \
              "Please try again in %{retry_cooldown_in_words}."
          ),
          retry_cooldown_in_words: distance_of_time_in_words(seconds_remaining)
        )

        ServiceResponse.error(message: message, reason: :too_many_requests)
      end
    end
  end
end
