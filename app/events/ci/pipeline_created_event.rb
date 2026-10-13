# frozen_string_literal: true

module Ci
  class PipelineCreatedEvent < ::Gitlab::EventStore::Event
    def schema
      {
        'type' => 'object',
        'required' => %w[pipeline_id partition_id],
        'properties' => {
          'pipeline_id' => { 'type' => 'integer' },
          'partition_id' => { 'type' => 'integer' },
          'pipeline_creation_request' => {
            'type' => 'object',
            'required' => %w[key id],
            'properties' => {
              'key' => { 'type' => 'string' },
              'id' => { 'type' => 'string' }
            }
          }
        }
      }
    end
  end
end
