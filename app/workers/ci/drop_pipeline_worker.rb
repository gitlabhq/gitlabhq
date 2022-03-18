# frozen_string_literal: true

module Ci
  class DropPipelineWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3
    include PipelineQueue

    urgency :high

    idempotent!

    def perform(pipeline_id, failure_reason)
      Ci::Pipeline.find_by_id(pipeline_id).try do |pipeline|
        Ci::DropPipelineService.new.execute(pipeline, failure_reason.to_sym)
      end
    end
  end
end
