# frozen_string_literal: true

module Ci
  module JobArtifacts
    class TrackArtifactReportWorker
      include ApplicationWorker

      data_consistency :delayed

      include PipelineBackgroundQueue

      feature_category :code_testing

      idempotent!

      def perform(pipeline_id)
        Ci::Pipeline.find_by_id(pipeline_id).try do |pipeline|
          Ci::JobArtifacts::TrackArtifactReportService.new.execute(pipeline)
        end
      end
    end
  end
end
