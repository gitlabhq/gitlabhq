# frozen_string_literal: true

module MergeRequests
  # Published from MergeRequests::CreatePipelineWorker#after_perform when an
  # MR-scoped pipeline creation attempt finishes. `pipeline_id` is set if a
  # Ci::Pipeline row was persisted, nil if creation produced no pipeline
  # (e.g. workflow:rules dropped it, missing CI config).
  class PipelineCreationCompletedEvent < ::Gitlab::EventStore::Event
    def schema
      {
        'type' => 'object',
        'required' => %w[merge_request_id project_id],
        'properties' => {
          'merge_request_id' => { 'type' => 'integer' },
          'project_id' => { 'type' => 'integer' },
          'pipeline_id' => { 'type' => %w[integer null] }
        }
      }
    end
  end
end
