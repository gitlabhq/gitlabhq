# frozen_string_literal: true

module Ci
  class PlayManualStageWorker
    include ApplicationWorker
    include PipelineQueue

    queue_namespace :pipeline_processing
    urgency :high
    idempotent!
    data_consistency :sticky
    deduplicate :until_executed
    worker_resource_boundary :cpu

    def perform(stage_id, user_id)
      stage = Ci::Stage.find_by_id(stage_id)
      user = User.find_by_id(user_id)

      return unless stage && user

      Ci::PlayManualStageService
        .new(stage.project, user, pipeline: stage.pipeline)
        .execute(stage)
    end
  end
end
