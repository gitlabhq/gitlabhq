# frozen_string_literal: true

module BulkImports
  module Importers
    class GroupImporter
      def initialize(entity)
        @entity = entity
      end

      def execute
        entity.start!
        bulk_import = entity.bulk_import
        configuration = bulk_import.configuration

        context = BulkImports::Pipeline::Context.new(
          current_user: bulk_import.user,
          entity: entity,
          configuration: configuration
        )

        BulkImports::Groups::Pipelines::GroupPipeline.new.run(context)
        'BulkImports::EE::Groups::Pipelines::EpicsPipeline'.constantize.new.run(context) if Gitlab.ee?
        BulkImports::Groups::Pipelines::SubgroupEntitiesPipeline.new.run(context)

        entity.finish!
      end

      private

      attr_reader :entity
    end
  end
end
