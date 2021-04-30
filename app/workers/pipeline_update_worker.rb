# frozen_string_literal: true

# This worker is deprecated and will be removed in 14.0
# See: https://gitlab.com/gitlab-org/gitlab/-/issues/232806
class PipelineUpdateWorker
  include ApplicationWorker

  sidekiq_options retry: 3
  include PipelineQueue

  queue_namespace :pipeline_processing
  urgency :high

  idempotent!

  def perform(_pipeline_id)
    # no-op
  end
end
