# frozen_string_literal: true

module BulkImports
  module Importers
    class GroupImporter
      def initialize(entity)
        @entity = entity
      end

      def execute
        pipelines.each.with_index do |pipeline, stage|
          pipeline_tracker = entity.trackers.create!(
            pipeline_name: pipeline,
            stage: stage
          )

          context = BulkImports::Pipeline::Context.new(pipeline_tracker)

          pipeline.new(context).run

          pipeline_tracker.finish!
        end

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
          BulkImports::Groups::Pipelines::MilestonesPipeline,
          BulkImports::Groups::Pipelines::BadgesPipeline
        ]
      end
    end
  end
end

BulkImports::Importers::GroupImporter.prepend_if_ee('EE::BulkImports::Importers::GroupImporter')
