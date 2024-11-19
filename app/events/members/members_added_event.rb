# frozen_string_literal: true

module Members
  class MembersAddedEvent < ::Gitlab::EventStore::Event
    def schema
      {
        'type' => 'object',
        'required' => %w[source_id source_type],
        'properties' => {
          'source_id' => { 'type' => 'integer' },
          'source_type' => { 'type' => 'string' },
          'invited_user_ids' => { 'type' => 'array' }
        }
      }
    end
  end
end
