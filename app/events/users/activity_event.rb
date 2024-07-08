# frozen_string_literal: true

module Users
  class ActivityEvent < ::Gitlab::EventStore::Event
    def schema
      {
        'type' => 'object',
        'required' => %w[user_id namespace_id],
        'properties' => {
          'user_id' => { 'type' => 'integer' },
          'namespace_id' => { 'type' => 'integer' }
        }
      }
    end
  end
end
