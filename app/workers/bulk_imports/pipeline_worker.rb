# frozen_string_literal: true

module BulkImports
  class PipelineWorker
    include ApplicationWorker
    include ExclusiveLeaseGuard
    include Gitlab::Utils::StrongMemoize
    include Sidekiq::InterruptionsExhausted

    FILE_EXTRACTION_PIPELINE_PERFORM_DELAY = 10.seconds

    LimitedBatches = Struct.new(:numbers, :final?, keyword_init: true).freeze

    DEFER_ON_HEALTH_DELAY = 5.minutes

    data_consistency :sticky
    feature_category :importers
    sidekiq_options dead: false, retry: 6
    sidekiq_options max_retries_after_interruption: 20
    worker_has_external_dependencies!
    deduplicate :until_executing
    worker_resource_boundary :memory
    idempotent!

    version 2

    sidekiq_retries_exhausted do |job, exception|
      new.perform_failure(job['args'][0], job['args'][2], exception)
    end

    sidekiq_interruptions_exhausted do |job|
      new.perform_failure(job['args'][0], job['args'][2], Import::Exceptions::SidekiqExhaustedInterruptionsError.new)
    end

    defer_on_database_health_signal(:gitlab_main, [], DEFER_ON_HEALTH_DELAY) do |job_args, schema, tables|
      pipeline_tracker = ::BulkImports::Tracker.find(job_args.first)
      pipeline_schema = ::BulkImports::PipelineSchemaInfo.new(
        pipeline_tracker.pipeline_class,
        pipeline_tracker.entity.portable_class
      )

      if pipeline_schema.db_schema && pipeline_schema.db_table
        schema = pipeline_schema.db_schema
        tables = [pipeline_schema.db_table]
      end

      [schema, tables]
    end

    def self.defer_on_database_health_signal?
      Feature.enabled?(:bulk_import_deferred_workers)
    end

    # Keep _stage parameter for backwards compatibility.
    def perform(pipeline_tracker_id, _stage, entity_id)
      @entity = ::BulkImports::Entity.find(entity_id)
      @pipeline_tracker = ::BulkImports::Tracker.find(pipeline_tracker_id)

      log_extra_metadata_on_done(:pipeline_class, @pipeline_tracker.pipeline_name)

      try_obtain_lease do
        if pipeline_tracker.enqueued? || pipeline_tracker.started?
          logger.info(log_attributes(message: 'Pipeline starting'))
          run
        end
      end
    end

    def perform_failure(pipeline_tracker_id, entity_id, exception)
      @entity = ::BulkImports::Entity.find(entity_id)
      @pipeline_tracker = ::BulkImports::Tracker.find(pipeline_tracker_id)

      fail_pipeline(exception)
    end

    private

    attr_reader :pipeline_tracker, :entity

    def run
      return if pipeline_tracker.canceled?
      return if invalid_entity_status?

      raise(Pipeline::FailedError, "Export from source instance failed: #{export_status.error}") if export_failed?
      raise(Pipeline::ExpiredError, 'Empty export status on source instance') if empty_export_timeout?

      return re_enqueue if export_empty? || export_started?

      if file_extraction_pipeline? && export_status.batched?
        log_extra_metadata_on_done(:batched, true)

        pipeline_tracker.update!(status_event: 'start', jid: jid, batched: true)

        return pipeline_tracker.finish! if export_status.batches_count < 1

        enqueue_limited_batches
        re_enqueue unless all_batches_enqueued?
      else
        log_extra_metadata_on_done(:batched, false)

        pipeline_tracker.update!(status_event: 'start', jid: jid)
        pipeline_tracker.pipeline_class.new(context).run
        pipeline_tracker.finish!
      end
    rescue BulkImports::RetryPipelineError => e
      retry_tracker(e)
    end

    def fail_pipeline(exception)
      pipeline_tracker.update!(status_event: 'fail_op', jid: jid)

      entity.fail_op! if pipeline_tracker.abort_on_failure?

      log_exception(exception, log_attributes(message: 'Pipeline failed'))

      Gitlab::ErrorTracking.track_exception(exception, log_attributes)

      BulkImports::Failure.create(
        bulk_import_entity_id: entity.id,
        pipeline_class: pipeline_tracker.pipeline_name,
        pipeline_step: 'pipeline_worker_run',
        exception_class: exception.class.to_s,
        exception_message: exception.message,
        correlation_id_value: Labkit::Correlation::CorrelationId.current_or_new_id
      )
    end

    def logger
      @logger ||= Logger.build.with_tracker(pipeline_tracker)
    end

    def re_enqueue(delay = FILE_EXTRACTION_PIPELINE_PERFORM_DELAY)
      log_extra_metadata_on_done(:re_enqueue, true)

      with_context(bulk_import_entity_id: entity.id) do
        self.class.perform_in(
          delay,
          pipeline_tracker.id,
          pipeline_tracker.stage,
          entity.id
        )
      end
    end

    def context
      @context ||= ::BulkImports::Pipeline::Context.new(pipeline_tracker)
    end

    def export_status
      @export_status ||= ExportStatus.new(pipeline_tracker, pipeline_tracker.pipeline_class.relation)
    end

    def file_extraction_pipeline?
      pipeline_tracker.file_extraction_pipeline?
    end

    def empty_export_timeout?
      export_empty? && time_since_tracker_created > Pipeline::EMPTY_EXPORT_STATUS_TIMEOUT
    end

    def export_failed?
      return false unless file_extraction_pipeline?

      export_status.failed?
    end

    def export_started?
      return false unless file_extraction_pipeline?

      export_status.started?
    end

    def export_empty?
      return false unless file_extraction_pipeline?

      export_status.empty?
    end

    def retry_tracker(exception)
      log_exception(exception, log_attributes(message: "Retrying pipeline"))

      pipeline_tracker.update!(status_event: 'retry', jid: jid)

      re_enqueue(exception.retry_delay)
    end

    def invalid_entity_status?
      if entity.failed?
        handle_invalid_status('skip', 'Skipping pipeline due to failed entity')
      elsif entity.timeout?
        handle_invalid_status('cleanup_stale', 'Timeout pipeline due to timeout entity')
      elsif entity.canceled?
        handle_invalid_status('cancel', 'Canceling pipeline due to canceled entity')
      else
        false
      end
    end

    def handle_invalid_status(status_event, message)
      logger.info(log_attributes(message: message))
      pipeline_tracker.update!(status_event: status_event, jid: jid)
      true
    end

    def log_attributes(extra = {})
      logger.default_attributes.merge(extra)
    end

    def log_exception(exception, payload)
      Gitlab::ExceptionLogFormatter.format!(exception, payload)

      logger.error(structured_payload(payload))
    end

    def time_since_tracker_created
      Time.zone.now - (pipeline_tracker.created_at || entity.created_at)
    end

    def enqueue_limited_batches
      next_batch.numbers.each do |batch_number|
        batch = pipeline_tracker.batches.create!(batch_number: batch_number)

        with_context(bulk_import_entity_id: entity.id) do
          ::BulkImports::PipelineBatchWorker.perform_async(batch.id)
        end
      end

      log_extra_metadata_on_done(:tracker_batch_numbers_enqueued, next_batch.numbers)
      log_extra_metadata_on_done(:tracker_final_batch_was_enqueued, next_batch.final?)
    end

    def all_batches_enqueued?
      next_batch.final?
    end

    def next_batch
      all_batch_numbers = (1..export_status.batches_count).to_a

      created_batch_numbers = pipeline_tracker.batches.pluck_batch_numbers

      remaining_batch_numbers = all_batch_numbers - created_batch_numbers

      limit = next_batch_count

      LimitedBatches.new(
        numbers: remaining_batch_numbers.first(limit),
        final?: remaining_batch_numbers.count <= limit
      )
    end
    strong_memoize_attr :next_batch

    # Calculate the number of batches, up to `batch_limit`, to process in the
    # next round.
    def next_batch_count
      limit = batch_limit - pipeline_tracker.batches.in_progress.limit(batch_limit).count
      [limit, 0].max
    end

    def batch_limit
      ::Gitlab::CurrentSettings.bulk_import_concurrent_pipeline_batch_limit
    end

    def lease_timeout
      30
    end

    def lease_key
      "gitlab:bulk_imports:pipeline_worker:#{pipeline_tracker.id}"
    end
  end
end
