# frozen_string_literal: true

class PipelineHooksWorker
  include ApplicationWorker
  include PipelineQueue

  queue_namespace :pipeline_hooks

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(pipeline_id)
    Ci::Pipeline.find_by(id: pipeline_id)
      .try(:execute_hooks)
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
