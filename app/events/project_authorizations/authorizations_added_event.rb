# frozen_string_literal: true

module ProjectAuthorizations
  class AuthorizationsAddedEvent < ::Gitlab::EventStore::Event
    def schema
      {
        'type' => 'object',
        'required' => %w[user_ids],
        'properties' => {
          'project_ids' => { 'type' => 'array' },
          'project_id' => { 'type' => 'integer' },
          'user_ids' => { 'type' => 'array' }
        }
      }
    end
  end
end
