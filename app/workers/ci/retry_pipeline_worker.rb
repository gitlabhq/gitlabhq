# frozen_string_literal: true

module Ci
  class RetryPipelineWorker
    include ::ApplicationWorker
    include ::PipelineQueue

    urgency :high
    worker_resource_boundary :cpu
    idempotent!
    deduplicate :until_executed, if_deduplicated: :reschedule_once

    def perform(pipeline_id, user_id)
      ::Ci::Pipeline.find_by_id(pipeline_id).try do |pipeline|
        ::User.find_by_id(user_id).try do |user|
          response = pipeline.retry_failed(user)
          next unless response.error?

          log_extra_metadata_on_done(:error_message, response.message)
          log_extra_metadata_on_done(:error_reason, response.reason)
        end
      end
    end
  end
end
