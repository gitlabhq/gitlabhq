# frozen_string_literal: true

module Ci
  class BuildTraceChunkFlushWorker
    include ApplicationWorker
    include PipelineBackgroundQueue

    urgency :high
    max_concurrency_limit_percentage 0.45
    data_consistency :sticky
    idempotent!
    deduplicate :until_executed
    sidekiq_options retry: false

    def perform(id)
      ::Ci::BuildTraceChunk.find_by_id(id).try do |chunk|
        chunk.persist_data!
      end
    end
  end
end
