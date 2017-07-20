class StageUpdateWorker
  include Sidekiq::Worker
  include PipelineQueue

  def perform(stage_id)
    Ci::Stage.find_by(id: stage_id)&.update!
  end
end
