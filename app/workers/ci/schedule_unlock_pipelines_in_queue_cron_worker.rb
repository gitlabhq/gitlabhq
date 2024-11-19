# frozen_string_literal: true

module Ci
  class ScheduleUnlockPipelinesInQueueCronWorker
    include ApplicationWorker

    data_consistency :always

    # rubocop:disable Scalability/CronWorkerContext
    # This worker does not perform work scoped to a context
    include CronjobQueue
    # rubocop:enable Scalability/CronWorkerContext

    feature_category :job_artifacts
    idempotent!

    def perform(...)
      Ci::UnlockPipelinesInQueueWorker.perform_with_capacity(...)
    end
  end
end
