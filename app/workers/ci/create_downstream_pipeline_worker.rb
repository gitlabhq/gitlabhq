# frozen_string_literal: true

module Ci
  class CreateDownstreamPipelineWorker # rubocop:disable Scalability/IdempotentWorker
    include ::ApplicationWorker
    include ::PipelineQueue

    sidekiq_options retry: 3
    worker_resource_boundary :cpu
    urgency :high

    def perform(bridge_id)
      Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/464668')

      ::Ci::Bridge.find_by_id(bridge_id).try do |bridge|
        result = ::Ci::CreateDownstreamPipelineService
          .new(bridge.project, bridge.user)
          .execute(bridge)

        if result.success?
          log_extra_metadata_on_done(:new_pipeline_id, result.payload.id)
        else
          log_extra_metadata_on_done(:create_error_message, result.message)
        end
      end
    end
  end
end
