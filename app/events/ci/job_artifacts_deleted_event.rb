# frozen_string_literal: true

module Ci
  class JobArtifactsDeletedEvent < ::Gitlab::EventStore::Event
    def schema
      {
        'type' => 'object',
        'required' => ['job_ids'],
        'properties' => {
          'job_ids' => {
            'type' => 'array',
            'items' => {
              'type' => 'integer'
            }
          }
        }
      }
    end
  end
end
