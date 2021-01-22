# frozen_string_literal: true

module Ci
  module PipelineArtifacts
    class CreateQualityReportWorker
      include ApplicationWorker

      queue_namespace :pipeline_background
      feature_category :code_testing

      idempotent!

      def perform(pipeline_id)
        Ci::Pipeline.find_by_id(pipeline_id).try do |pipeline|
          Ci::PipelineArtifacts::CreateQualityReportService.new.execute(pipeline)
        end
      end
    end
  end
end
