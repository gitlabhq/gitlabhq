class BuildTraceTTLRefreshWorker
  include ApplicationWorker
  include CronjobQueue

  def perform
    Ci::JobTraceChunk.redis # Stored in redis
      .joins(:ci_builds)
      .where('NOT EXISTS (?)', # If the trace has not been archived yet
        Ci::JobArtifact.select(1).trace.where('ci_builds.id = ci_job_artifacts.job_id'))
      .where('ci_builds.update_at < ?', CHUNK_REDIS_TTL_REFRESH.ago) # If the live-trace has not been updated over 6h
      .find_in_batches(batch_size: 1000) do |job_trace_chunks|
      BuildTraceTTLExtendWorker.perform_async(job_trace_chunks.minimum(:id), job_trace_chunks.maximum(:id))
    end
  end
end
