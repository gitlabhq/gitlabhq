# frozen_string_literal: true

# rubocop: disable Scalability/IdempotentWorker
class ExpirePipelineCacheWorker
  include ApplicationWorker

  sidekiq_options retry: 3
  include PipelineQueue

  queue_namespace :pipeline_cache
  urgency :high
  worker_resource_boundary :cpu
  data_consistency :delayed

  # This worker _should_ be idempotent, but due to us moving this to data_consistency :delayed
  # and an ongoing incompatibility between the two switches, we need to disable this.
  # Uncomment once https://gitlab.com/gitlab-org/gitlab/-/issues/325291 is resolved
  # idempotent!

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(pipeline_id)
    pipeline = Ci::Pipeline.eager_load_project.find_by(id: pipeline_id)
    return unless pipeline

    Ci::ExpirePipelineCacheService.new.execute(pipeline)
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
# rubocop:enable Scalability/IdempotentWorker
