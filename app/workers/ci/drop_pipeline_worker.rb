# frozen_string_literal: true

module Ci
  class DropPipelineWorker
    include ApplicationWorker

    sidekiq_options retry: 3
    include PipelineQueue

    tags :exclude_from_kubernetes

    idempotent!

    def perform(pipeline_id, failure_reason)
      Ci::Pipeline.find_by_id(pipeline_id).try do |pipeline|
        Ci::DropPipelineService.new.execute(pipeline, failure_reason.to_sym)
      end
    end
  end
end
