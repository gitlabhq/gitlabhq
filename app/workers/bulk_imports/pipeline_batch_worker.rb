# frozen_string_literal: true

module BulkImports
  class PipelineBatchWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker
    include ExclusiveLeaseGuard

    data_consistency :always # rubocop:disable SidekiqLoadBalancing/WorkerDataConsistency
    feature_category :importers
    sidekiq_options retry: false, dead: false
    worker_has_external_dependencies!
    worker_resource_boundary :memory

    def perform(batch_id)
      @batch = ::BulkImports::BatchTracker.find(batch_id)
      @tracker = @batch.tracker

      try_obtain_lease { run }
    ensure
      ::BulkImports::FinishBatchedPipelineWorker.perform_async(tracker.id)
    end

    private

    attr_reader :batch, :tracker

    def run
      return batch.skip! if tracker.failed? || tracker.finished?

      batch.start!
      tracker.pipeline_class.new(context).run
      batch.finish!
    rescue BulkImports::RetryPipelineError => e
      retry_batch(e)
    rescue StandardError => e
      fail_batch(e)
    end

    def fail_batch(exception)
      batch.fail_op!

      Gitlab::ErrorTracking.track_exception(
        exception,
        batch_id: batch.id,
        tracker_id: tracker.id,
        pipeline_class: tracker.pipeline_name,
        pipeline_step: 'pipeline_batch_worker_run'
      )

      BulkImports::Failure.create(
        bulk_import_entity_id: batch.tracker.entity.id,
        pipeline_class: tracker.pipeline_name,
        pipeline_step: 'pipeline_batch_worker_run',
        exception_class: exception.class.to_s,
        exception_message: exception.message.truncate(255),
        correlation_id_value: Labkit::Correlation::CorrelationId.current_or_new_id
      )
    end

    def context
      @context ||= ::BulkImports::Pipeline::Context.new(tracker, batch_number: batch.batch_number)
    end

    def retry_batch(exception)
      batch.retry!

      re_enqueue(exception.retry_delay)
    end

    def lease_timeout
      30
    end

    def lease_key
      "gitlab:bulk_imports:pipeline_batch_worker:#{batch.id}"
    end

    def re_enqueue(delay = FILE_EXTRACTION_PIPELINE_PERFORM_DELAY)
      self.class.perform_in(delay, batch.id)
    end
  end
end
