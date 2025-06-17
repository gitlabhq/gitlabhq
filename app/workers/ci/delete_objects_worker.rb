# frozen_string_literal: true

module Ci
  class DeleteObjectsWorker
    include ApplicationWorker
    include CronjobChildWorker

    data_consistency :always

    sidekiq_options retry: 3
    include LimitedCapacity::Worker

    feature_category :continuous_integration
    idempotent!

    def perform_work(*args)
      service.execute
    end

    def remaining_work_count(*args)
      @remaining_work_count ||= service
        .remaining_batches_count(max_batch_count: max_running_jobs)
    end

    def max_running_jobs
      20
    end

    private

    def service
      @service ||= DeleteObjectsService.new
    end
  end
end
