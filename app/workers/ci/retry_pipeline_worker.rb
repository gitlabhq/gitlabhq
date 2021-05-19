# frozen_string_literal: true

module Ci
  class RetryPipelineWorker # rubocop:disable Scalability/IdempotentWorker
    include ::ApplicationWorker
    include ::PipelineQueue

    urgency :high
    worker_resource_boundary :cpu

    def perform(pipeline_id, user_id)
      ::Ci::Pipeline.find_by_id(pipeline_id).try do |pipeline|
        ::User.find_by_id(user_id).try do |user|
          pipeline.retry_failed(user)
        end
      end
    end
  end
end
