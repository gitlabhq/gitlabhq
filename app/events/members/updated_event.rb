# frozen_string_literal: true

module Members
  class UpdatedEvent < ::Gitlab::EventStore::Event
    def schema
      {
        'type' => 'object',
        'required' => %w[source_id source_type user_ids],
        'properties' => {
          'source_id' => { 'type' => 'integer' },
          'source_type' => { 'type' => 'string' },
          'user_ids' => {
            'type' => 'array',
            'items' => { 'type' => 'integer' }
          }
        }
      }
    end
  end
end
