class PipelineSuccessWorker
  include Sidekiq::Worker
  include PipelineQueue

  def perform(pipeline_id)
    Ci::Pipeline.find_by(id: pipeline_id).try do |pipeline|
      MergeRequests::MergeWhenBuildSucceedsService
        .new(pipeline.project, nil)
        .trigger(pipeline)
    end
  end
end
