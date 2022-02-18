# frozen_string_literal: true

class ExpireJobCacheWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :delayed

  sidekiq_options retry: 3
  include PipelineQueue

  queue_namespace :pipeline_cache
  urgency :high
  idempotent!

  def perform(job_id)
    job = CommitStatus.find_by_id(job_id)
    return unless job

    job.expire_etag_cache!
    ExpirePipelineCacheWorker.perform_async(job.pipeline_id)
  end
end
