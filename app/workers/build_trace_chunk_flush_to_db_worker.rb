class BuildTraceChunkFlushToDBWorker
  include ApplicationWorker
  include PipelineQueue

  queue_namespace :pipeline_processing

  def perform(build_trace_chunk_id)
    Ci::BuildTraceChunk.find_by(id: build_trace_chunk_id).try do |build_trace_chunk|
      build_trace_chunk.use_database!
    end
  end
end
