# frozen_string_literal: true

module Ci
  class TrackAiPipelineResultsViewedService
    def initialize(pipeline)
      @pipeline = pipeline
    end

    def execute(user_id)
      return unless Ci::ProjectMetric.ai_pipeline_results_trackable?(@pipeline.project_id)

      Ci::TrackAiPipelineResultsViewedWorker.perform_async(@pipeline.id, user_id)
    end
  end
end
