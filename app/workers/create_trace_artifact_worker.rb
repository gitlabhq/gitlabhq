class CreateTraceArtifactWorker
  include ApplicationWorker
  include PipelineQueue

  def perform(job_id)
    Ci::Build.preload(:project, :user).find_by(id: job_id).try do |job|
      Ci::CreateTraceArtifactService.new(job.project, job.user).execute(job)
    end
  end
end
