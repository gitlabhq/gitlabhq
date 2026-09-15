# frozen_string_literal: true

module BulkImports
  module Common
    module Pipelines
      class EntityFinisher
        include Gitlab::InternalEventsTracking

        def self.file_extraction_pipeline?
          false
        end

        def self.abort_on_failure?
          false
        end

        def initialize(context)
          @context = context
          @entity = @context.entity
          @trackers = @entity.trackers
        end

        def run
          return if entity.finished? || entity.failed?

          if all_other_trackers_failed?
            entity.fail_op!
          else
            entity.finish!
          end

          logger.info(
            pipeline_class: self.class.name,
            message: "Entity #{entity.status_name}"
          )

          schedule_group_work_item_placement if entity.group?

          return unless entity.project?

          ::BulkImports::FinishProjectImportWorker.perform_async(entity.project_id)
          track_finish_project_import if entity.finished?
        end

        private

        attr_reader :context, :entity, :trackers

        def track_finish_project_import
          return unless entity.project

          track_internal_event('finish_project_import', entity.project_import_event_attributes)
        end

        def logger
          @logger ||= Logger.build.with_entity(entity)
        end

        def all_other_trackers_failed?
          trackers.where.not(relation: self.class.name).all? { |tracker| tracker.failed? } # rubocop: disable CodeReuse/ActiveRecord
        end

        def schedule_group_work_item_placement
          return unless entity.group

          ::Issues::PlacementWorker.perform_async(
            { 'namespace_id' => entity.group.work_item_positioning_root.id }
          )
        end
      end
    end
  end
end
