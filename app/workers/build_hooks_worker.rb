class BuildHooksWorker
  include ApplicationWorker
  include PipelineQueue

  queue_namespace :pipeline_hooks

  def perform(build_id)
    Ci::Build.find_by(id: build_id)
      .try(:execute_hooks)
  end
end
