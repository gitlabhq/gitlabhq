# frozen_string_literal: true

module Repositories
  class KeepAroundRefsCreatedEvent < ::Gitlab::EventStore::Event
    def schema
      {
        'type' => 'object',
        'properties' => {
          'project_id' => { 'type' => 'integer' }
        }
      }
    end
  end
end
