# frozen_string_literal: true

module Ci
  class ScheduleDeleteObjectsCronWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3
    # rubocop:disable Scalability/CronWorkerContext
    # This worker does not perform work scoped to a context
    include CronjobQueue
    # rubocop:enable Scalability/CronWorkerContext

    feature_category :continuous_integration
    tags :exclude_from_kubernetes
    idempotent!

    def perform(*args)
      Ci::DeleteObjectsWorker.perform_with_capacity(*args)
    end
  end
end
