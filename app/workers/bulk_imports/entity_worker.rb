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
      @entity = ::BulkImports::Entity.find(entity_id)

      if stage_running?(entity_id, current_stage)
        logger.info(
          structured_payload(
            bulk_import_entity_id: entity_id,
            bulk_import_id: entity.bulk_import_id,
            bulk_import_entity_type: entity.source_type,
            source_full_path: entity.source_full_path,
            current_stage: current_stage,
            message: 'Stage running',
            source_version: source_version,
            importer: 'gitlab_migration'
          )
        )

        return
      end

      logger.info(
        structured_payload(
          bulk_import_entity_id: entity_id,
          bulk_import_id: entity.bulk_import_id,
          bulk_import_entity_type: entity.source_type,
          source_full_path: entity.source_full_path,
          current_stage: current_stage,
          message: 'Stage starting',
          source_version: source_version,
          importer: 'gitlab_migration'
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
      log_exception(e,
        {
          bulk_import_entity_id: entity_id,
          bulk_import_id: entity.bulk_import_id,
          bulk_import_entity_type: entity.source_type,
          source_full_path: entity.source_full_path,
          current_stage: current_stage,
          message: 'Entity failed',
          source_version: source_version,
          importer: 'gitlab_migration'
        }
      )

      Gitlab::ErrorTracking.track_exception(
        e,
        bulk_import_entity_id: entity_id,
        bulk_import_id: entity.bulk_import_id,
        bulk_import_entity_type: entity.source_type,
        source_full_path: entity.source_full_path,
        source_version: source_version,
        importer: 'gitlab_migration'
      )

      entity.fail_op!
    end

    private

    attr_reader :entity

    def stage_running?(entity_id, stage)
      return unless stage

      BulkImports::Tracker.stage_running?(entity_id, stage)
    end

    def next_pipeline_trackers_for(entity_id)
      BulkImports::Tracker.next_pipeline_trackers_for(entity_id).update(status_event: 'enqueue')
    end

    def source_version
      entity.bulk_import.source_version_info.to_s
    end

    def logger
      @logger ||= Gitlab::Import::Logger.build
    end

    def log_exception(exception, payload)
      Gitlab::ExceptionLogFormatter.format!(exception, payload)

      logger.error(structured_payload(payload))
    end
  end
end
