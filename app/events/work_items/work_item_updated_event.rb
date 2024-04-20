# frozen_string_literal: true

module WorkItems
  class WorkItemUpdatedEvent < Gitlab::EventStore::Event
    def schema
      {
        'type' => 'object',
        'required' => %w[id namespace_id],
        'properties' => {
          'id' => { 'type' => 'integer' },
          'namespace_id' => { 'type' => 'integer' },
          'previous_work_item_parent_id' => { 'type' => 'integer' },
          'updated_attributes' => {
            'type' => 'array',
            'items' => {
              'type' => 'string'
            }
          },
          'updated_widgets' => {
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
