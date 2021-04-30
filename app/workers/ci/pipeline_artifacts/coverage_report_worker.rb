# frozen_string_literal: true

module Ci
  module PipelineArtifacts
    class CoverageReportWorker
      include ApplicationWorker

      sidekiq_options retry: 3
      include PipelineBackgroundQueue

      feature_category :code_testing

      idempotent!

      def perform(pipeline_id)
        Ci::Pipeline.find_by_id(pipeline_id).try do |pipeline|
          Ci::PipelineArtifacts::CoverageReportService.new.execute(pipeline)
        end
      end
    end
  end
end
