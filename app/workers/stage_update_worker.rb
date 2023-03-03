# frozen_string_literal: true

# This will be scheduled to be removed after removing the FF ci_remove_ensure_stage_service
class StageUpdateWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  include PipelineQueue

  queue_namespace :pipeline_processing
  urgency :high

  idempotent!

  def perform(stage_id)
    Ci::Stage.find_by_id(stage_id)&.update_legacy_status
  end
end
