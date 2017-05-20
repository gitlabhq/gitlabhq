class ExpireJobCacheWorker
  include Sidekiq::Worker
  include BuildQueue

  def perform(pipeline_id, job_id)
    job = CommitStatus.joins(:pipeline, :project).find_by(id: job)
    return unless job

    pipeline = job.pipeline
    project = job.project

    store.touch(project_pipeline_path(project, pipeline))
    store.touch(project_job_path(project, job))
  end

  private

  def project_pipeline_path(project, pipeline)
    Gitlab::Routing.url_helpers.namespace_project_pipeline_path(
      project.namespace,
      project,
      pipeline,
      format: :json)
  end

  def project_job_path(project, job)
    Gitlab::Routing.url_helpers.namespace_project_build_path(
      project.namespace,
      project,
      job.id,
      format: :json)
  end

  def store
    @store ||= Gitlab::EtagCaching::Store.new
  end
end
