# frozen_string_literal: true

module Members
  class AcceptedInviteEvent < ::Gitlab::EventStore::Event
    def schema
      {
        'type' => 'object',
        'required' => %w[source_id source_type user_id member_id],
        'properties' => {
          'member_id' => { 'type' => 'integer' },
          'source_id' => { 'type' => 'integer' },
          'source_type' => { 'type' => 'string' },
          'user_id' => { 'type' => 'integer' }
        }
      }
    end
  end
end
