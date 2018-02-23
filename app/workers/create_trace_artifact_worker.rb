class CreateTraceArtifactWorker
  include ApplicationWorker
  include PipelineQueue

  # TODO: this worker should use BackgroundMigration or ObjectStorage queue

  def perform(job_id)
    Ci::Build.preload(:project, :user).find_by(id: job_id).try do |job|
      job.trace.archive!
    end
  end
end
