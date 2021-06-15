# frozen_string_literal: true

module BulkImports
  module Groups
    module Pipelines
      class EntityFinisher
        def self.ndjson_pipeline?
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
            bulk_import_id: context.bulk_import.id,
            bulk_import_entity_id: context.entity.id,
            bulk_import_entity_type: context.entity.source_type,
            pipeline_class: self.class.name,
            message: "Entity #{entity.status_name}"
          )
        end

        private

        attr_reader :context, :entity, :trackers

        def logger
          @logger ||= Gitlab::Import::Logger.build
        end

        def all_other_trackers_failed?
          trackers.where.not(relation: self.class.name).all? { |tracker| tracker.failed? } # rubocop: disable CodeReuse/ActiveRecord
        end
      end
    end
  end
end
