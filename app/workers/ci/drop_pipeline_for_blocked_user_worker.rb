# frozen_string_literal: true

module Ci
  # Low-urgency variant of DropPipelineWorker used when canceling pipelines
  # as part of a user block. Blocking a user can affect a large number of
  # pipelines, so pipeline drops are processed at low urgency to avoid
  # starving other high-priority pipeline workers.
  class DropPipelineForBlockedUserWorker < DropPipelineWorker
    data_consistency :delayed
    defer_on_database_health_signal :gitlab_ci, [:p_ci_pipelines, :p_ci_builds], 1.minute
    urgency :low
    idempotent!
  end
end
