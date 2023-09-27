# frozen_string_literal: true

module BulkImports
  class EntityWorker
    include ApplicationWorker

    idempotent!
    deduplicate :until_executed
    data_consistency :always
    feature_category :importers
    sidekiq_options retry: false, dead: false
    worker_has_external_dependencies!

    PERFORM_DELAY = 5.seconds

    # Keep `_current_stage` parameter for backwards compatibility.
    # The parameter will be remove in https://gitlab.com/gitlab-org/gitlab/-/issues/426311
    def perform(entity_id, _current_stage = nil)
      @entity = ::BulkImports::Entity.find(entity_id)

      return unless @entity.started?

      if running_tracker.present?
        log_info(message: 'Stage running', entity_stage: running_tracker.stage)
      else
        start_next_stage
      end

      re_enqueue
    rescue StandardError => e
      Gitlab::ErrorTracking.track_exception(e, log_params(message: 'Entity failed'))

      @entity.fail_op!
    end

    private

    attr_reader :entity

    def re_enqueue
      BulkImports::EntityWorker.perform_in(PERFORM_DELAY, entity.id)
    end

    def running_tracker
      @running_tracker ||= BulkImports::Tracker.running_trackers(entity.id).first
    end

    def next_pipeline_trackers_for(entity_id)
      BulkImports::Tracker.next_pipeline_trackers_for(entity_id).update(status_event: 'enqueue')
    end

    def start_next_stage
      next_pipeline_trackers = next_pipeline_trackers_for(entity.id)

      next_pipeline_trackers.each_with_index do |pipeline_tracker, index|
        log_info(message: 'Stage starting', entity_stage: pipeline_tracker.stage) if index == 0

        BulkImports::PipelineWorker.perform_async(
          pipeline_tracker.id,
          pipeline_tracker.stage,
          entity.id
        )
      end
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

    def log_info(payload)
      logger.info(structured_payload(log_params(payload)))
    end

    def log_params(extra)
      defaults = {
        bulk_import_entity_id: entity.id,
        bulk_import_id: entity.bulk_import_id,
        bulk_import_entity_type: entity.source_type,
        source_full_path: entity.source_full_path,
        source_version: source_version,
        importer: 'gitlab_migration'
      }

      defaults.merge(extra)
    end
  end
end
