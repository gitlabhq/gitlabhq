class StashTraceChunkWorker
  include ApplicationWorker
  include PipelineQueue

  queue_namespace :pipeline_processing

  def perform(job_trace_chunk_id)
    Ci::JobTraceChunk.find_by(id: job_trace_chunk_id).try do |job_trace_chunk|
      job_trace_chunk.use_database!
    end
  end
end
