# frozen_string_literal: true

class ExpirePipelineCacheWorker
  include ApplicationWorker

  sidekiq_options retry: 3
  include PipelineQueue

  queue_namespace :pipeline_cache
  urgency :high
  worker_resource_boundary :cpu

  idempotent!

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(pipeline_id)
    pipeline = Ci::Pipeline.eager_load_project.find_by(id: pipeline_id)
    return unless pipeline

    Ci::ExpirePipelineCacheService.new.execute(pipeline)
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
