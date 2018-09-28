# frozen_string_literal: true

class BuildHooksWorker
  include ApplicationWorker
  include PipelineQueue

  queue_namespace :pipeline_hooks

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(build_id)
    Ci::Build.find_by(id: build_id)
      .try(:execute_hooks)
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
