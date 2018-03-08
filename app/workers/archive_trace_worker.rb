class ArchiveTraceWorker
  include ApplicationWorker
  include PipelineBackgroundQueue

  def perform(job_id)
    Ci::Build.find_by(id: job_id).try do |job|
      job.trace.archive!
    end
  end
end
