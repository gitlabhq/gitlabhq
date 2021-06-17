# frozen_string_literal: true

class PipelineHooksWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  sidekiq_options retry: 3
  include PipelineQueue

  queue_namespace :pipeline_hooks
  worker_resource_boundary :cpu
  data_consistency :delayed

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(pipeline_id)
    Ci::Pipeline.includes({ builds: { runner: :tags } })
      .find_by(id: pipeline_id)
      .try(:execute_hooks)
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
