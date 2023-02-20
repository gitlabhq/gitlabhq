# frozen_string_literal: true

module Ci
  class ScheduleDeleteObjectsCronWorker
    include ApplicationWorker

    data_consistency :always

    # rubocop:disable Scalability/CronWorkerContext
    # This worker does not perform work scoped to a context
    include CronjobQueue
    # rubocop:enable Scalability/CronWorkerContext

    feature_category :continuous_integration
    idempotent!

    def perform(...)
      Ci::DeleteObjectsWorker.perform_with_capacity(...)
    end
  end
end
