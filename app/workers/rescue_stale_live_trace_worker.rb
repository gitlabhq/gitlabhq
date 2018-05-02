class RescueStaleLiveTraceWorker
  include ApplicationWorker
  include CronjobQueue

  def perform
    # Reschedule to archive live traces
    #
    # The target jobs are with the following conditions
    # - Finished 4 hours ago, but it's not archived yet
    #   Jobs finished 4 hours ago should have an archived trace. Probably ArchiveTraceWorker failed by Sidekiq's inconsistancy
    Ci::Build.finished
      .where('finished_at BETWEEN ? AND ?', 1.week.ago, 4.hours.ago)
      .where('NOT EXISTS (?)', Ci::JobArtifact.select(1).trace.where('ci_builds.id = ci_job_artifacts.job_id'))
      .find_in_batch(batch_size: 1000) do |jobs|
        job_ids = jobs.map { |job| [job.id] }

        ArchiveTraceWorker.bulk_perform_async(job_ids)

        Rails.logger.warning "Scheduled to archive stale live traces from #{job_ids.min} to #{job_ids.max}"
      end

    # Schedule to flush redis-chunk to database
    #
    # The target build_trace_chunks are with the following conditions
    # - The last patching of the trace was 1 hour ago
    # - The job is still running
    Ci::BuildTraceChunk.redis
      .joins(:build)
      .where('ci_builds.update_at < ?', 1.hour.ago)
      .where('ci_builds.status = ?', 'running')
      .find_in_batch(batch_size: 1000) do |build_trace_chunks|
        build_trace_chunk_ids = build_trace_chunks.map { |build_trace_chunk| [build_trace_chunk.id] }

        BuildTraceChunkFlushToDBWorker.bulk_perform_async(build_trace_chunk_ids)

        Rails.logger.warning "Scheduled to flush stale live traces to database from #{build_trace_chunk_ids.min} to #{build_trace_chunk_ids.max}"
      end
  end
end
