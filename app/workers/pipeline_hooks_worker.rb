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
    pipeline = Ci::Pipeline.find_by(id: pipeline_id)
    return unless pipeline

    Ci::Pipelines::HookService.new(pipeline).execute
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
