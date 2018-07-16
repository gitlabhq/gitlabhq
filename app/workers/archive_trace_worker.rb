# frozen_string_literal: true

class ArchiveTraceWorker
  include ApplicationWorker
  include PipelineBackgroundQueue

  def perform(job_id)
    Ci::Build.without_archived_trace.find_by(id: job_id).try do |job|
      job.trace.archive!
    end
  end
end
