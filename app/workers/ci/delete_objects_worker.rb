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
      response = service.execute

      # Temporararily logging deletion_delay_metrics to Kibana to evaluate deletion speed.
      # The average speed will be used to determine an acceptable latency for a service monitoring SLI and alert
      # To be removed once an acceptable delay is determined.

      log_extra_metadata_on_done(:deletion_delay_metrics, deletion_delay_metrics(response[:latencies]))
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

    def deletion_delay_metrics(latencies)
      return { min: nil, max: nil, sum: 0, average: nil, total_count: 0 } if latencies.blank?

      latencies = latencies.map(&:to_f)

      sum = latencies.sum
      size = latencies.size

      {
        min: latencies.min,
        max: latencies.max,
        sum: sum,
        average: sum / size,
        total_count: size
      }
    end
  end
end
