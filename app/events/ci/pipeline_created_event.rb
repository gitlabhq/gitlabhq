# frozen_string_literal: true

module Ci
  class PipelineCreatedEvent < ::Gitlab::EventStore::Event
    def schema
      {
        'type' => 'object',
        'required' => ['pipeline_id'],
        'properties' => {
          'pipeline_id' => { 'type' => 'integer' }
        }
      }
    end
  end
end
