# frozen_string_literal: true

module Ci
  module PipelineArtifacts
    class CoverageReportWorker
      include ApplicationWorker

      data_consistency :sticky

      sidekiq_options retry: 3
      include PipelineBackgroundQueue

      feature_category :code_testing

      idempotent!
      deduplicate :until_executed

      def perform(pipeline_id)
        pipeline = Ci::Pipeline.find_by_id(pipeline_id)

        return unless pipeline

        pipeline.root_ancestor.try do |root_ancestor_pipeline|
          next unless root_ancestor_pipeline.self_and_project_descendants_complete?

          Ci::PipelineArtifacts::CoverageReportService.new(root_ancestor_pipeline).execute
        end
      end
    end
  end
end
