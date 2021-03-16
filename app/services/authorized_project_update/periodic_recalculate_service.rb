# frozen_string_literal: true

module AuthorizedProjectUpdate
  class PeriodicRecalculateService
    BATCH_SIZE = 450
    DELAY_INTERVAL = 50.seconds.to_i

    def execute
      # Using this approach (instead of eg. User.each_batch) keeps the arguments
      # the same for AuthorizedProjectUpdate::UserRefreshOverUserRangeWorker
      # even if the user list changes, so we can deduplicate these jobs.
      (1..User.maximum(:id)).each_slice(BATCH_SIZE).with_index do |batch, index|
        delay = DELAY_INTERVAL * index
        AuthorizedProjectUpdate::UserRefreshOverUserRangeWorker.perform_in(delay, *batch.minmax)
      end
    end
  end
end
