# frozen_string_literal: true

module Groups
  class GroupDeletedEvent < ::Gitlab::EventStore::Event
    def schema
      {
        'type' => 'object',
        'properties' => {
          'group_id' => { 'type' => 'integer' },
          'root_namespace_id' => { 'type' => 'integer' }
        },
        'required' => %w[group_id root_namespace_id]
      }
    end
  end
end
