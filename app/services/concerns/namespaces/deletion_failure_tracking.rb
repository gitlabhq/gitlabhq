# frozen_string_literal: true

module Namespaces
  # Reports group and project destroy failures, and escalates deletions that look stuck.
  module DeletionFailureTracking
    # Dedicated error class so Sentry can group and alert on stuck deletions independently.
    DeletionStuckError = Class.new(StandardError)

    # Escalate when attempt_count >= MAX_DESTROY_ATTEMPTS AND the previous failure is older than
    # STUCK_FAILURE_WINDOW, so a burst of failures inside one incident doesn't count as stuck.
    # Retries are not capped.
    MAX_DESTROY_ATTEMPTS = 5
    STUCK_FAILURE_WINDOW = 12.hours

    private

    def track_destroy_failure(entity, error, previous_failed_at, **context)
      attempt_count = entity.deletion_attempt_count.to_i

      Gitlab::ErrorTracking.track_exception(
        error,
        **Gitlab::ApplicationContext.current.merge(
          **context,
          full_path: entity.full_path,
          deletion_attempt_count: attempt_count
        )
      )

      # A destroyed entity (after_commit hook failure) was not rescheduled, so it is not stuck.
      return if entity.destroyed?

      return unless attempt_count >= MAX_DESTROY_ATTEMPTS &&
        previous_failed_at.present? &&
        previous_failed_at <= STUCK_FAILURE_WINDOW.ago

      Gitlab::ErrorTracking.track_exception(
        DeletionStuckError.new("#{entity.class.name} stuck in deletion: #{error.message}"),
        **Gitlab::ApplicationContext.current.merge(
          **context,
          deletion_attempt_count: attempt_count,
          deletion_last_failed_at: previous_failed_at
        )
      )
    end
  end
end
