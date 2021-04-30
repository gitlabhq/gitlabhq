# frozen_string_literal: true

module Ci
  class BuildTraceChunkFlushWorker
    include ApplicationWorker

    sidekiq_options retry: 3
    include PipelineBackgroundQueue

    deduplicate :until_executed

    idempotent!

    # rubocop: disable CodeReuse/ActiveRecord
    def perform(id)
      ::Ci::BuildTraceChunk.find_by(id: id).try do |chunk|
        chunk.persist_data!
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
