# frozen_string_literal: true

module Members
  class DestroyedEvent < ::Gitlab::EventStore::Event
    def schema
      {
        'type' => 'object',
        'required' => %w[source_id source_type user_id],
        'properties' => {
          'root_namespace_id' => { 'type' => 'integer' },
          'source_id' => { 'type' => 'integer' },
          'source_type' => { 'type' => 'string' },
          'user_id' => { 'type' => %w[integer null] }
        }
      }
    end
  end
end
