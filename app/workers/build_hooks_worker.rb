class BuildHooksWorker
  include ApplicationWorker
  include PipelineQueue

  enqueue_in group: :hooks

  def perform(build_id)
    Ci::Build.find_by(id: build_id)
      .try(:execute_hooks)
  end
end
