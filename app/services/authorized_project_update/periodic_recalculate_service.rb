# frozen_string_literal: true

module AuthorizedProjectUpdate
  class PeriodicRecalculateService
    BATCH_SIZE = 450
    DELAY_INTERVAL = 50.seconds.to_i

    def execute
      # Using this approach (instead of eg. User.each_batch) keeps the arguments
      # the same for AuthorizedProjectUpdate::UserRefreshOverUserRangeWorker
      # even if the user list changes, so we can deduplicate these jobs.

      # Since UserRefreshOverUserRangeWorker has set data_consistency to delayed,
      # a job enqueued without a delay could fail because the replica could not catch up with the primary.
      # To prevent this, we start the index from `1` instead of `0` so as to ensure that
      # no UserRefreshOverUserRangeWorker job is enqueued without a delay.
      (1..User.maximum(:id)).each_slice(BATCH_SIZE).with_index(1) do |batch, index|
        delay = DELAY_INTERVAL * index
        AuthorizedProjectUpdate::UserRefreshOverUserRangeWorker.perform_in(delay, *batch.minmax)
      end
    end
  end
end
