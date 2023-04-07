# frozen_string_literal: true

module BulkImports
  class PipelineWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker
    include ExclusiveLeaseGuard

    FILE_EXTRACTION_PIPELINE_PERFORM_DELAY = 10.seconds

    data_consistency :always
    feature_category :importers
    sidekiq_options retry: false, dead: false
    worker_has_external_dependencies!
    deduplicate :until_executing
    worker_resource_boundary :memory

    def perform(pipeline_tracker_id, stage, entity_id)
      @entity = ::BulkImports::Entity.find(entity_id)
      @pipeline_tracker = ::BulkImports::Tracker.find(pipeline_tracker_id)

      try_obtain_lease do
        if pipeline_tracker.enqueued?
          logger.info(log_attributes(message: 'Pipeline starting'))

          run
        else
          message = "Pipeline in #{pipeline_tracker.human_status_name} state instead of expected enqueued state"

          logger.error(log_attributes(message: message))

          fail_tracker(StandardError.new(message)) unless pipeline_tracker.finished? || pipeline_tracker.skipped?
        end
      end

    ensure
      ::BulkImports::EntityWorker.perform_async(entity_id, stage)
    end

    private

    attr_reader :pipeline_tracker, :entity

    def run
      return skip_tracker if entity.failed?

      raise(Pipeline::ExpiredError, 'Pipeline timeout') if job_timeout?
      raise(Pipeline::FailedError, "Export from source instance failed: #{export_status.error}") if export_failed?
      raise(Pipeline::ExpiredError, 'Empty export status on source instance') if empty_export_timeout?

      return re_enqueue if export_empty? || export_started?

      pipeline_tracker.update!(status_event: 'start', jid: jid)
      pipeline_tracker.pipeline_class.new(context).run
      pipeline_tracker.finish!
    rescue BulkImports::RetryPipelineError => e
      retry_tracker(e)
    rescue StandardError => e
      fail_tracker(e)
    end

    def source_version
      entity.bulk_import.source_version_info.to_s
    end

    def fail_tracker(exception)
      pipeline_tracker.update!(status_event: 'fail_op', jid: jid)

      log_exception(exception, log_attributes(message: 'Pipeline failed'))

      Gitlab::ErrorTracking.track_exception(exception, log_attributes)

      BulkImports::Failure.create(
        bulk_import_entity_id: entity.id,
        pipeline_class: pipeline_tracker.pipeline_name,
        pipeline_step: 'pipeline_worker_run',
        exception_class: exception.class.to_s,
        exception_message: exception.message.truncate(255),
        correlation_id_value: Labkit::Correlation::CorrelationId.current_or_new_id
      )
    end

    def logger
      @logger ||= Gitlab::Import::Logger.build
    end

    def re_enqueue(delay = FILE_EXTRACTION_PIPELINE_PERFORM_DELAY)
      self.class.perform_in(
        delay,
        pipeline_tracker.id,
        pipeline_tracker.stage,
        entity.id
      )
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

    def skip_tracker
      logger.info(log_attributes(message: 'Skipping pipeline due to failed entity'))

      pipeline_tracker.update!(status_event: 'skip', jid: jid)
    end

    def log_attributes(extra = {})
      structured_payload(
        {
          bulk_import_entity_id: entity.id,
          bulk_import_id: entity.bulk_import_id,
          bulk_import_entity_type: entity.source_type,
          source_full_path: entity.source_full_path,
          pipeline_tracker_id: pipeline_tracker.id,
          pipeline_name: pipeline_tracker.pipeline_name,
          pipeline_tracker_state: pipeline_tracker.human_status_name,
          source_version: source_version,
          importer: 'gitlab_migration'
        }.merge(extra)
      )
    end

    def log_exception(exception, payload)
      Gitlab::ExceptionLogFormatter.format!(exception, payload)

      logger.error(structured_payload(payload))
    end

    def time_since_tracker_created
      Time.zone.now - (pipeline_tracker.created_at || entity.created_at)
    end

    def lease_timeout
      30
    end

    def lease_key
      "gitlab:bulk_imports:pipeline_worker:#{pipeline_tracker.id}"
    end

    def job_timeout?
      return false unless file_extraction_pipeline?

      time_since_tracker_created > Pipeline::NDJSON_EXPORT_TIMEOUT
    end
  end
end
