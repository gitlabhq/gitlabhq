# frozen_string_literal: true

module BulkImports
  module Common
    module Pipelines
      class EntityFinisher
        def self.file_extraction_pipeline?
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
            bulk_import_id: entity.bulk_import_id,
            bulk_import_entity_id: entity.id,
            bulk_import_entity_type: entity.source_type,
            source_full_path: entity.source_full_path,
            pipeline_class: self.class.name,
            message: "Entity #{entity.status_name}",
            source_version: entity.bulk_import.source_version_info.to_s,
            importer: 'gitlab_migration'
          )

          context.portable.try(:after_import)
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
