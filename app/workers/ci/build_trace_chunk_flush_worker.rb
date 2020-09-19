# frozen_string_literal: true

module Ci
  class BuildTraceChunkFlushWorker
    include ApplicationWorker
    include PipelineBackgroundQueue

    idempotent!

    # rubocop: disable CodeReuse/ActiveRecord
    def perform(chunk_id)
      ::Ci::BuildTraceChunk.find_by(id: chunk_id).try do |chunk|
        chunk.persist_data!
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
