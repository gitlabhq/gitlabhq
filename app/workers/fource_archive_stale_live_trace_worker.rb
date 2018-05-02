class FourceArchiveStaleLiveTraceWorker
  include ApplicationWorker
  include CronjobQueue

  def perform
    # Find jobs with the following condition
    # - Finished 4 hours ago (Jobs finished 4 hours ago should have an archived trace)
    # - Not archived yet (Because ArchiveTraceWorker failed by some reason)
    Ci::Build.finished
      .where('finished_at < ?', 4.hours.ago)
      .where('NOT EXISTS (?)', Ci::JobArtifact.select(1).trace.where('ci_builds.id = ci_job_artifacts.job_id'))
      .find_each(batch_size: 1000) do |job|
        begin
          job.trace.archive!
        rescue => e
          Rails.logger.error "#{job.id}: Failed to archive stable live trace: #{e.message}"
        end

        Rails.logger.warning "#{job.id}: Live trace was force archived because it was considered as stale"
      end
    end
  end
end
