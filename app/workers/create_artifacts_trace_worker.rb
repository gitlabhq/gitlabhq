class CreateArtifactsTraceWorker
  include ApplicationWorker
  include PipelineQueue

  def perform(job_id)
    Ci::CreateArtifactsTraceService.new.execute(job_id)
  end
end
