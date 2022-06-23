# frozen_string_literal: true

module Ci
  module PipelineArtifacts
    class CoverageReportWorker
      include ApplicationWorker

      data_consistency :always

      sidekiq_options retry: 3
      include PipelineBackgroundQueue

      feature_category :code_testing

      idempotent!

      def perform(pipeline_id)
        pipeline = Ci::Pipeline.find_by_id(pipeline_id)

        return unless pipeline

        if Feature.enabled?(:ci_child_pipeline_coverage_reports, pipeline.project)
          pipeline.root_ancestor.try do |root_ancestor_pipeline|
            next unless root_ancestor_pipeline.self_and_descendants_complete?

            Ci::PipelineArtifacts::CoverageReportService.new(root_ancestor_pipeline).execute
          end
        else
          Ci::PipelineArtifacts::CoverageReportService.new(pipeline).execute
        end
      end
    end
  end
end
