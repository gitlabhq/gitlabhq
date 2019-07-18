# frozen_string_literal: true

class ArchiveTraceWorker
  include ApplicationWorker
  include PipelineBackgroundQueue

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(job_id)
    Ci::Build.without_archived_trace.find_by(id: job_id).try do |job|
      Ci::ArchiveTraceService.new.execute(job, worker_name: self.class.name)
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
