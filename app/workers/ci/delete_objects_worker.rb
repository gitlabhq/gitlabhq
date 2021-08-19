# frozen_string_literal: true

module Ci
  class DeleteObjectsWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3
    include LimitedCapacity::Worker

    feature_category :continuous_integration
    tags :exclude_from_kubernetes
    idempotent!

    def perform_work(*args)
      service.execute
    end

    def remaining_work_count(*args)
      @remaining_work_count ||= service
        .remaining_batches_count(max_batch_count: max_running_jobs)
    end

    def max_running_jobs
      if ::Feature.enabled?(:ci_delete_objects_medium_concurrency)
        20
      elsif ::Feature.enabled?(:ci_delete_objects_high_concurrency)
        50
      else
        2
      end
    end

    private

    def service
      @service ||= DeleteObjectsService.new
    end
  end
end
