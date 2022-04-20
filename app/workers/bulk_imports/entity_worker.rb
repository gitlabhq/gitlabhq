# frozen_string_literal: true

module BulkImports
  class EntityWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    idempotent!
    deduplicate :until_executing
    data_consistency :always
    feature_category :importers
    sidekiq_options retry: false, dead: false
    worker_has_external_dependencies!

    def perform(entity_id, current_stage = nil)
      if stage_running?(entity_id, current_stage)
        logger.info(
          structured_payload(
            entity_id: entity_id,
            current_stage: current_stage,
            message: 'Stage running'
          )
        )

        return
      end

      logger.info(
        structured_payload(
          entity_id: entity_id,
          current_stage: current_stage,
          message: 'Stage starting'
        )
      )

      next_pipeline_trackers_for(entity_id).each do |pipeline_tracker|
        BulkImports::PipelineWorker.perform_async(
          pipeline_tracker.id,
          pipeline_tracker.stage,
          entity_id
        )
      end
    rescue StandardError => e
      logger.error(
        structured_payload(
          entity_id: entity_id,
          current_stage: current_stage,
          message: e.message
        )
      )

      Gitlab::ErrorTracking.track_exception(e, entity_id: entity_id)
    end

    private

    def stage_running?(entity_id, stage)
      return unless stage

      BulkImports::Tracker.stage_running?(entity_id, stage)
    end

    def next_pipeline_trackers_for(entity_id)
      BulkImports::Tracker.next_pipeline_trackers_for(entity_id).update(status_event: 'enqueue')
    end

    def logger
      @logger ||= Gitlab::Import::Logger.build
    end
  end
end
