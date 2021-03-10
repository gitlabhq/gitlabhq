# frozen_string_literal: true

module BulkImports
  module Importers
    class GroupImporter
      def initialize(entity)
        @entity = entity
      end

      def execute
        context = BulkImports::Pipeline::Context.new(entity)

        pipelines.each { |pipeline| pipeline.new(context).run }

        entity.finish!
      end

      private

      attr_reader :entity

      def pipelines
        [
          BulkImports::Groups::Pipelines::GroupPipeline,
          BulkImports::Groups::Pipelines::SubgroupEntitiesPipeline,
          BulkImports::Groups::Pipelines::MembersPipeline,
          BulkImports::Groups::Pipelines::LabelsPipeline,
          BulkImports::Groups::Pipelines::MilestonesPipeline
        ]
      end
    end
  end
end

BulkImports::Importers::GroupImporter.prepend_if_ee('EE::BulkImports::Importers::GroupImporter')
