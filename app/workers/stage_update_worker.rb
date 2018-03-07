class StageUpdateWorker
  include ApplicationWorker
  include PipelineQueue

  queue_namespace :pipeline_processing

  def perform(stage_id)
    Ci::Stage.find_by(id: stage_id).try do |stage|
      stage.update_status
    end
  end
end
