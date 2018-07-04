# frozen_string_literal: true

class ArchiveTraceWorker
  include ApplicationWorker
  include PipelineBackgroundQueue

  def perform(job_id)
    Ci::Build.find_by(id: job_id).try do |job|
      job.trace.archive! unless build.job_artifacts_trace
    end
  end
end
