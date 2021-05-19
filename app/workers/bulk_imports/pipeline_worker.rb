# frozen_string_literal: true

module BulkImports
  class PipelineWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    feature_category :importers
    tags :exclude_from_kubernetes

    sidekiq_options retry: false, dead: false

    worker_has_external_dependencies!

    def perform(pipeline_tracker_id, stage, entity_id)
      pipeline_tracker = ::BulkImports::Tracker
        .with_status(:created)
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
      pipeline_tracker.update!(status_event: 'start', jid: jid)

      context = ::BulkImports::Pipeline::Context.new(pipeline_tracker)

      pipeline_tracker.pipeline_class.new(context).run

      pipeline_tracker.finish!
    rescue StandardError => e
      pipeline_tracker.fail_op!

      logger.error(
        worker: self.class.name,
        entity_id: pipeline_tracker.entity.id,
        pipeline_name: pipeline_tracker.pipeline_name,
        message: e.message
      )

      Gitlab::ErrorTracking.track_exception(
        e,
        entity_id: pipeline_tracker.entity.id,
        pipeline_name: pipeline_tracker.pipeline_name
      )
    end

    def logger
      @logger ||= Gitlab::Import::Logger.build
    end
  end
end
