# frozen_string_literal: true

module Ci
  class CreateCrossProjectPipelineWorker # rubocop:disable Scalability/IdempotentWorker
    include ::ApplicationWorker
    include ::PipelineQueue

    sidekiq_options retry: 3
    worker_resource_boundary :cpu

    def perform(bridge_id)
      ::Ci::Bridge.find_by_id(bridge_id).try do |bridge|
        ::Ci::CreateDownstreamPipelineService
          .new(bridge.project, bridge.user)
          .execute(bridge)
      end
    end
  end
end
