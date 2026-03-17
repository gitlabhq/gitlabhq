# frozen_string_literal: true

module AuthorizedProjectUpdate
  class PeriodicRecalculateService
    BATCH_SIZE = 450
    DELAY_INTERVAL = 50.seconds.to_i

    def execute
      # Since UserRefreshOverUserRangeWorker has set data_consistency to delayed,
      # a job enqueued without a delay could fail because the replica could not catch up with the primary.
      # each_batch yields a 1-based index, ensuring no job is enqueued without a delay.
      User.each_batch(of: BATCH_SIZE) do |relation, index|
        delay = DELAY_INTERVAL * index
        start_id, end_id = relation.pick(Arel.sql('MIN(id), MAX(id)'))

        AuthorizedProjectUpdate::UserRefreshOverUserRangeWorker.perform_in(delay, start_id, end_id)
      end
    end
  end
end
