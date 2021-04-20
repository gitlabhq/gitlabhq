# frozen_string_literal: true

module BulkImports
  module Groups
    module Pipelines
      class EntityFinisher
        def initialize(context)
          @context = context
        end

        def run
          return if context.entity.finished?

          context.entity.finish!

          logger.info(
            bulk_import_id: context.bulk_import.id,
            bulk_import_entity_id: context.entity.id,
            bulk_import_entity_type: context.entity.source_type,
            pipeline_class: self.class.name,
            message: 'Entity finished'
          )
        end

        private

        attr_reader :context

        def logger
          @logger ||= Gitlab::Import::Logger.build
        end
      end
    end
  end
end
