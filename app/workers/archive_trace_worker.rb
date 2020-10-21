# frozen_string_literal: true

class ArchiveTraceWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker
  include PipelineBackgroundQueue

  tags :requires_disk_io

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(job_id)
    Ci::Build.without_archived_trace.find_by(id: job_id).try do |job|
      Ci::ArchiveTraceService.new.execute(job, worker_name: self.class.name)
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
