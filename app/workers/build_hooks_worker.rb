# frozen_string_literal: true

class BuildHooksWorker
  include ApplicationWorker
  include PipelineQueue

  queue_namespace :pipeline_hooks
  feature_category :continuous_integration

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(build_id)
    Ci::Build.find_by(id: build_id)
      .try(:execute_hooks)
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
