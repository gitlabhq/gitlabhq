# frozen_string_literal: true

module WorkItems
  class BulkUpdatedEvent < Gitlab::EventStore::Event
    def schema
      {
        'type' => 'object',
        'required' => %w[work_item_ids],
        'properties' => {
          'work_item_ids' => {
            'type' => 'array',
            'items' => { 'type' => 'integer' }
          },
          'root_namespace_id' => { 'type' => 'integer' }
        },
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
    end
  end
end
