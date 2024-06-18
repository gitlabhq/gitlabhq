# frozen_string_literal: true

module Milestones # rubocop: disable Gitlab/BoundedContexts -- event created before the bounded context
  class MilestoneUpdatedEvent < Gitlab::EventStore::Event
    def schema
      {
        'type' => 'object',
        'required' => %w[id],
        'properties' => {
          'id' => { 'type' => 'integer' },
          'group_id' => { 'type' => 'integer' },
          'project_id' => { 'type' => 'integer' },
          'updated_attributes' => {
            'type' => 'array',
            'items' => {
              'type' => 'string'
            }
          }
        }
      }
    end
  end
end
