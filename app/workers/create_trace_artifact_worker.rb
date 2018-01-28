class CreateTraceArtifactWorker
  include ApplicationWorker
  include PipelineQueue

  def perform(job_id)
    Ci::Build.find_by(id: job_id).try do |job|
      Ci::CreateTraceArtifactService.new.execute(job)
    end
  end
end
