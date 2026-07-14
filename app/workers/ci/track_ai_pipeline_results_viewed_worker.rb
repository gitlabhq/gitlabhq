# frozen_string_literal: true

module Ci
  class TrackAiPipelineResultsViewedWorker
    include ApplicationWorker
    include Gitlab::InternalEventsTracking

    data_consistency :sticky
    feature_category :pipeline_composition
    urgency :low
    idempotent!
    concurrency_limit -> { 1000 }
    defer_on_database_health_signal :gitlab_ci, [:ci_project_metrics], 1.minute

    def perform(pipeline_id, user_id)
      pipeline = Ci::Pipeline.find_by_id(pipeline_id)
      return unless pipeline
      return unless Ci::ProjectMetric.mark_ai_pipeline_results_viewed(pipeline.project_id, pipeline.created_at) == 1

      track_internal_event(
        'view_ai_pipeline_results',
        project: pipeline.project,
        user: User.find_by_id(user_id),
        additional_properties: {
          author_source: Ci::ProjectMetric.ci_config_generated_by_for(pipeline.project_id)
        }
      )
    end
  end
end
