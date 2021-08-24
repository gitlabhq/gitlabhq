# frozen_string_literal: true

class ExpireJobCacheWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :delayed, feature_flag: :load_balancing_for_expire_job_cache_worker

  sidekiq_options retry: 3
  include PipelineQueue

  queue_namespace :pipeline_cache
  urgency :high
  # This worker should be idempotent, but we're switching to data_consistency
  # :sticky and there is an ongoing incompatibility, so it needs to be disabled for
  # now. The following line can be uncommented and this comment removed once
  # https://gitlab.com/gitlab-org/gitlab/-/issues/325291 is resolved.
  # idempotent!

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(job_id)
    job = CommitStatus.eager_load_pipeline.find_by(id: job_id)
    return unless job

    pipeline = job.pipeline
    project = job.project

    Gitlab::EtagCaching::Store.new.touch(project_job_path(project, job))
    ExpirePipelineCacheWorker.perform_async(pipeline.id)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  private

  def project_job_path(project, job)
    Gitlab::Routing.url_helpers.project_build_path(project, job.id, format: :json)
  end
end
