# frozen_string_literal: true

module MergeRequests
  module PublishesPipelineCreationCompletedEvent
    private

    def publish_pipeline_creation_completed_event(project:, merge_request_id:, pipeline_id:)
      ::Gitlab::EventStore.publish(
        ::MergeRequests::PipelineCreationCompletedEvent.new(data: {
          merge_request_id: merge_request_id,
          project_id: project.id,
          pipeline_id: pipeline_id
        }.compact)
      )
    end
  end
end
