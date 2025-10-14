# frozen_string_literal: true

module Ci
  class PipelineFinishedEvent < ::Gitlab::EventStore::Event
    def schema
      {
        'type' => 'object',
        'required' => %w[pipeline_id status],
        'properties' => {
          'pipeline_id' => { 'type' => 'integer' },
          'status' => { 'type' => 'string' }
        }
      }
    end
  end
end
