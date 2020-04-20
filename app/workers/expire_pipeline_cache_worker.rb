# frozen_string_literal: true

class ExpirePipelineCacheWorker
  include ApplicationWorker
  include PipelineQueue

  queue_namespace :pipeline_cache
  urgency :high
  worker_resource_boundary :cpu

  idempotent!

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(pipeline_id)
    pipeline = Ci::Pipeline.find_by(id: pipeline_id)
    return unless pipeline&.cacheable?

    Ci::ExpirePipelineCacheService.new.execute(pipeline)
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
