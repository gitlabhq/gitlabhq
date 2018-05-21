class RescueStaleLiveTraceWorker
  include ApplicationWorker
  include CronjobQueue

  def perform
    # Reschedule to archive live traces
    #
    # The target jobs are with the following conditions
    # - Finished 1 day ago, but it has not had an acthived trace yet
    #   Jobs finished 1 day ago should have an archived trace. Probably ArchiveTraceWorker failed by Sidekiq's inconsistancy
    Ci::Build.finished
      .where('finished_at BETWEEN ? AND ?', 1.week.ago, 1.day.ago)
      .where('NOT EXISTS (?)', Ci::JobArtifact.select(1).trace.where('ci_builds.id = ci_job_artifacts.job_id'))
      .find_in_batch(batch_size: 100) do |jobs|
        job_ids = jobs.map { |job| [job.id] }

        ArchiveTraceWorker.bulk_perform_async(job_ids)

        Rails.logger.warning "Scheduled to archive stale live traces from #{job_ids.min} to #{job_ids.max}"
      end
  end
end
