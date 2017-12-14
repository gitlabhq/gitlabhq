class PipelineHooksWorker
  include ApplicationWorker
  include PipelineQueue

  queue_namespace :pipeline_hooks

  def perform(pipeline_id)
    Ci::Pipeline.find_by(id: pipeline_id)
      .try(:execute_hooks)
  end
end
