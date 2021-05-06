# frozen_string_literal: true

module Ci
  module PipelineArtifacts
    class CreateQualityReportWorker
      include ApplicationWorker

      sidekiq_options retry: 3

      queue_namespace :pipeline_background
      feature_category :code_testing
      tags :exclude_from_kubernetes

      idempotent!

      def perform(pipeline_id)
        Ci::Pipeline.find_by_id(pipeline_id).try do |pipeline|
          Ci::PipelineArtifacts::CreateCodeQualityMrDiffReportService.new(pipeline).execute
        end
      end
    end
  end
end
