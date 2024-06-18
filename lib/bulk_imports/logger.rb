# frozen_string_literal: true

module BulkImports
  class Logger < ::Import::Framework::Logger
    IMPORTER_NAME = 'gitlab_migration'

    # Extract key information from a provided entity and include it in log
    # entries created from this logger instance.
    # @param entity [BulkImports::Entity]
    def with_entity(entity)
      @entity = entity
      self
    end

    # Extract key information from a provided tracker and its entity and include
    # it in log entries created from this logger instance.
    # @param tracker [BulkImports::Tracker]
    def with_tracker(tracker)
      with_entity(tracker.entity)
      @tracker = tracker
      self
    end

    def entity_attributes
      return {} unless entity

      {
        bulk_import_id: entity.bulk_import_id,
        bulk_import_entity_id: entity.id,
        bulk_import_entity_type: entity.source_type,
        source_full_path: entity.source_full_path,
        source_version: entity.source_version.to_s
      }
    end

    def tracker_attributes
      return {} unless tracker

      {
        tracker_id: tracker.id,
        pipeline_class: tracker.pipeline_name,
        tracker_state: tracker.human_status_name
      }
    end

    def default_attributes
      super.merge(
        { importer: IMPORTER_NAME },
        entity_attributes,
        tracker_attributes
      )
    end

    private

    attr_reader :entity, :tracker
  end
end
