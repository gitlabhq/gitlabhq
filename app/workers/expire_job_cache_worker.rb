# frozen_string_literal: true

class ExpireJobCacheWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :delayed

  sidekiq_options retry: 3
  include PipelineQueue

  queue_namespace :pipeline_cache
  urgency :high

  deduplicate :until_executing, including_scheduled: true
  idempotent!

  def perform(job_id)
    job = CommitStatus.preload(:pipeline, :project).find_by_id(job_id) # rubocop: disable CodeReuse/ActiveRecord
    return unless job

    pipeline = job.pipeline
    project = job.project

    Gitlab::EtagCaching::Store.new.touch(project_job_path(project, job))
    ExpirePipelineCacheWorker.perform_async(pipeline.id)
  end

  private

  def project_job_path(project, job)
    Gitlab::Routing.url_helpers.project_build_path(project, job.id, format: :json)
  end
end
