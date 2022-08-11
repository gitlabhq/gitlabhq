# frozen_string_literal: true

module Groups
  class GroupTransferedEvent < ::Gitlab::EventStore::Event
    def schema
      {
        'type' => 'object',
        'properties' => {
          'group_id' => { 'type' => 'integer' },
          'old_root_namespace_id' => { 'type' => 'integer' },
          'new_root_namespace_id' => { 'type' => 'integer' }
        },
        'required' => %w[group_id old_root_namespace_id new_root_namespace_id]
      }
    end
  end
end
