# frozen_string_literal: true

module Ci
  class PipelineBridgeStatusWorker # rubocop:disable Scalability/IdempotentWorker
    include ::ApplicationWorker
    include ::PipelineQueue

    sidekiq_options retry: 3
    urgency :high
    worker_resource_boundary :cpu

    def perform(pipeline_id)
      ::Ci::Pipeline.find_by_id(pipeline_id).try do |pipeline|
        ::Ci::PipelineBridgeStatusService
          .new(pipeline.project, pipeline.user)
          .execute(pipeline)
      end
    end
  end
end
