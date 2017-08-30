class StageUpdateWorker
  include Sidekiq::Worker
  include PipelineQueue

  enqueue_in group: :processing

  def perform(stage_id)
    Ci::Stage.find_by(id: stage_id).try do |stage|
      stage.update_status
    end
  end
end
