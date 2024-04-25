# frozen_string_literal: true

module Ci
  class PipelineSuccessUnlockArtifactsWorker
    include ApplicationWorker
    include PipelineBackgroundQueue

    data_consistency :always

    sidekiq_options retry: 3

    idempotent!

    defer_on_database_health_signal :gitlab_ci, [:ci_job_artifacts]

    def perform(pipeline_id); end
  end
end
