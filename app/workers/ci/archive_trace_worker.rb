# frozen_string_literal: true

module Ci
  class ArchiveTraceWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :sticky, feature_flag: :sticky_ci_archive_trace_worker

    sidekiq_options retry: 3
    include PipelineBackgroundQueue

    def perform(job_id)
      archivable_jobs = Ci::Build.without_archived_trace

      if Feature.enabled?(:sticky_ci_archive_trace_worker)
        archivable_jobs = archivable_jobs.eager_load_for_archiving_trace
      end

      archivable_jobs.find_by_id(job_id).try do |job|
        Ci::ArchiveTraceService.new.execute(job, worker_name: self.class.name)
      end
    end
  end
end
