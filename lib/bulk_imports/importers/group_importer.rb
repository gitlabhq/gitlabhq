# frozen_string_literal: true

module BulkImports
  module Importers
    class GroupImporter
      def initialize(entity)
        @entity = entity
      end

      def execute
        bulk_import = entity.bulk_import
        configuration = bulk_import.configuration

        context = BulkImports::Pipeline::Context.new(
          current_user: bulk_import.user,
          entity: entity,
          configuration: configuration
        )

        pipelines.each { |pipeline| pipeline.new.run(context) }

        entity.finish!
      end

      private

      attr_reader :entity

      def pipelines
        [
          BulkImports::Groups::Pipelines::GroupPipeline,
          BulkImports::Groups::Pipelines::SubgroupEntitiesPipeline
        ]
      end
    end
  end
end

BulkImports::Importers::GroupImporter.prepend_if_ee('EE::BulkImports::Importers::GroupImporter')
