# frozen_string_literal: true

module Ci
  class TrackPipelineTriggerEventsWorker
    include Gitlab::EventStore::Subscriber
    include Gitlab::InternalEventsTracking

    data_consistency :sticky
    feature_category :continuous_integration
    urgency :low
    defer_on_database_health_signal :gitlab_ci, [:p_ci_builds, :ci_pipelines], 1.minute

    idempotent!

    def handle_event(event)
      pipeline = Ci::Pipeline.in_partition(event.data[:partition_id]).find_by_id(event.data[:pipeline_id])
      return unless pipeline

      user_type = pipeline.user&.bot? ? 'bot' : 'human'

      track_internal_event(
        'ci_pipeline_triggered',
        user: pipeline.user,
        project: pipeline.project,
        additional_properties: { user_type: user_type }
      )

      pipeline.builds.find_each do |build|
        track_internal_event(
          'ci_build_triggered',
          user: build.user,
          project: pipeline.project,
          additional_properties: { user_type: user_type }
        )
      end
    end
  end
end
