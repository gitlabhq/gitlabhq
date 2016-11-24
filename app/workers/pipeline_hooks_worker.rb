class PipelineHooksWorker
  include Sidekiq::Worker
  include PipelineQueue

  def perform(pipeline_id)
    Ci::Pipeline.find_by(id: pipeline_id)
      .try(:execute_hooks)
  end
end
