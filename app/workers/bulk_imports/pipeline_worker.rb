# frozen_string_literal: true

module BulkImports
  class PipelineWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always

    NDJSON_PIPELINE_PERFORM_DELAY = 1.minute

    feature_category :importers

    sidekiq_options retry: false, dead: false

    worker_has_external_dependencies!

    def perform(pipeline_tracker_id, stage, entity_id)
      pipeline_tracker = ::BulkImports::Tracker
        .with_status(:enqueued)
        .find_by_id(pipeline_tracker_id)

      if pipeline_tracker.present?
        logger.info(
          worker: self.class.name,
          entity_id: pipeline_tracker.entity.id,
          pipeline_name: pipeline_tracker.pipeline_name
        )

        run(pipeline_tracker)
      else
        logger.error(
          worker: self.class.name,
          entity_id: entity_id,
          pipeline_tracker_id: pipeline_tracker_id,
          message: 'Unstarted pipeline not found'
        )
      end

    ensure
      ::BulkImports::EntityWorker.perform_async(entity_id, stage)
    end

    private

    def run(pipeline_tracker)
      if pipeline_tracker.entity.failed?
        raise(Entity::FailedError, 'Failed entity status')
      end

      if ndjson_pipeline?(pipeline_tracker)
        status = ExportStatus.new(pipeline_tracker, pipeline_tracker.pipeline_class.relation)

        raise(Pipeline::ExpiredError, 'Pipeline timeout') if job_timeout?(pipeline_tracker)
        raise(Pipeline::FailedError, status.error) if status.failed?

        return reenqueue(pipeline_tracker) if status.started?
      end

      pipeline_tracker.update!(status_event: 'start', jid: jid)

      context = ::BulkImports::Pipeline::Context.new(pipeline_tracker)

      pipeline_tracker.pipeline_class.new(context).run

      pipeline_tracker.finish!
    rescue BulkImports::NetworkError => e
      if e.retriable?(pipeline_tracker)
        logger.error(
          worker: self.class.name,
          entity_id: pipeline_tracker.entity.id,
          pipeline_name: pipeline_tracker.pipeline_name,
          message: "Retrying error: #{e.message}"
        )

        pipeline_tracker.update!(status_event: 'retry', jid: jid)

        reenqueue(pipeline_tracker, delay: e.retry_delay)
      else
        fail_tracker(pipeline_tracker, e)
      end
    rescue StandardError => e
      fail_tracker(pipeline_tracker, e)
    end

    def fail_tracker(pipeline_tracker, exception)
      pipeline_tracker.update!(status_event: 'fail_op', jid: jid)

      logger.error(
        worker: self.class.name,
        entity_id: pipeline_tracker.entity.id,
        pipeline_name: pipeline_tracker.pipeline_name,
        message: exception.message
      )

      Gitlab::ErrorTracking.track_exception(
        exception,
        entity_id: pipeline_tracker.entity.id,
        pipeline_name: pipeline_tracker.pipeline_name
      )
    end

    def logger
      @logger ||= Gitlab::Import::Logger.build
    end

    def ndjson_pipeline?(pipeline_tracker)
      pipeline_tracker.pipeline_class.ndjson_pipeline?
    end

    def job_timeout?(pipeline_tracker)
      (Time.zone.now - pipeline_tracker.entity.created_at) > Pipeline::NDJSON_EXPORT_TIMEOUT
    end

    def reenqueue(pipeline_tracker, delay: NDJSON_PIPELINE_PERFORM_DELAY)
      self.class.perform_in(
        delay,
        pipeline_tracker.id,
        pipeline_tracker.stage,
        pipeline_tracker.entity.id
      )
    end
  end
end
