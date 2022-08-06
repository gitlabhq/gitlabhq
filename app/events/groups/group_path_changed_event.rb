# frozen_string_literal: true

module Groups
  class GroupPathChangedEvent < ::Gitlab::EventStore::Event
    def schema
      {
        'type' => 'object',
        'properties' => {
          'group_id' => { 'type' => 'integer' },
          'root_namespace_id' => { 'type' => 'integer' },
          'old_path' => { 'type' => 'string' },
          'new_path' => { 'type' => 'string' }
        },
        'required' => %w[group_id root_namespace_id old_path new_path]
      }
    end
  end
end
