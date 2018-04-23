class BuildTraceTTLRefreshWorker
  include ApplicationWorker
  include PipelineQueue

  queue_namespace :pipeline_processing

  def perform(job_trace_chunk_id_min, job_trace_chunk_id_max)
    Ci::JobTraceChunk.redis
      .where(:id => (job_trace_chunk_id_min..job_trace_chunk_id_max))
      .map(&:redis_extend_ttl)
  end
end
