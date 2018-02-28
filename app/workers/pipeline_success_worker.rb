class PipelineSuccessWorker
  include ApplicationWorker
  include PipelineQueue

  queue_namespace :pipeline_processing

  def perform(pipeline_id)
    Ci::Pipeline.find_by(id: pipeline_id).try do |pipeline|
      MergeRequests::MergeWhenPipelineSucceedsService
        .new(pipeline.project, nil)
        .trigger(pipeline)
    end
  end
end
