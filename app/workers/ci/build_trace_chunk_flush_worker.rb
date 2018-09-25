# frozen_string_literal: true

module Ci
  class BuildTraceChunkFlushWorker
    include ApplicationWorker
    include PipelineBackgroundQueue

    # rubocop: disable CodeReuse/ActiveRecord
    def perform(build_trace_chunk_id)
      ::Ci::BuildTraceChunk.find_by(id: build_trace_chunk_id).try do |build_trace_chunk|
        build_trace_chunk.persist_data!
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
