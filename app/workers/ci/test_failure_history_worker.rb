# frozen_string_literal: true

module Ci
  class TestFailureHistoryWorker
    include ApplicationWorker
    include PipelineBackgroundQueue

    idempotent!

    def perform(pipeline_id)
      Ci::Pipeline.find_by_id(pipeline_id).try do |pipeline|
        Ci::TestFailureHistoryService.new(pipeline).execute
      end
    end
  end
end
