# frozen_string_literal: true

module Ci
  class TestFailureHistoryWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3
    include PipelineBackgroundQueue

    tags :exclude_from_kubernetes

    idempotent!

    def perform(pipeline_id)
      Ci::Pipeline.find_by_id(pipeline_id).try do |pipeline|
        Ci::TestFailureHistoryService.new(pipeline).execute
      end
    end
  end
end
