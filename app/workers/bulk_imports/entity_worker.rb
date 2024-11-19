# frozen_string_literal: true

module BulkImports
  class EntityWorker
    include ApplicationWorker
    include ExclusiveLeaseGuard

    idempotent!
    deduplicate :until_executing
    data_consistency :sticky
    feature_category :importers
    sidekiq_options retry: 3, dead: false
    worker_has_external_dependencies!

    sidekiq_retries_exhausted do |msg, exception|
      new.perform_failure(exception, msg['args'].first)
    end

    PERFORM_DELAY = 5.seconds

    def perform(entity_id)
      @entity = ::BulkImports::Entity.find(entity_id)

      return unless @entity.started?

      if running_tracker.present?
        log_info(message: 'Stage running', entity_stage: running_tracker.stage)
      else
        # Use lease guard to prevent duplicated workers from starting multiple stages
        try_obtain_lease do
          start_next_stage
        end
      end

      re_enqueue
    end

    def perform_failure(exception, entity_id)
      @entity = ::BulkImports::Entity.find(entity_id)

      Gitlab::ErrorTracking.track_exception(
        exception,
        {
          message: "Request to export #{entity.source_type} failed"
        }.merge(logger.default_attributes)
      )

      entity.fail_op!
    end

    private

    attr_reader :entity

    def re_enqueue
      with_context(bulk_import_entity_id: entity.id) do
        BulkImports::EntityWorker.perform_in(PERFORM_DELAY, entity.id)
      end
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

        with_context(bulk_import_entity_id: entity.id) do
          BulkImports::PipelineWorker.perform_async(
            pipeline_tracker.id,
            pipeline_tracker.stage,
            entity.id
          )

          if Import::BulkImports::EphemeralData.new(entity.bulk_import.id).importer_user_mapping_enabled?
            Import::LoadPlaceholderReferencesWorker.perform_async(
              Import::SOURCE_DIRECT_TRANSFER,
              entity.bulk_import.id,
              'current_user_id' => entity.bulk_import.user_id
            )
          end
        end
      end
    end

    def lease_timeout
      PERFORM_DELAY
    end

    def lease_key
      "gitlab:bulk_imports:entity_worker:#{entity.id}"
    end

    def log_lease_taken
      log_info(message: lease_taken_message)
    end

    def logger
      @logger ||= Logger.build.with_entity(entity)
    end

    def log_info(payload)
      logger.info(structured_payload(payload))
    end
  end
end
