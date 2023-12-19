# frozen_string_literal: true

module ProjectAuthorizations
  class AuthorizationsRemovedEvent < ::Gitlab::EventStore::Event
    def schema
      {
        'type' => 'object',
        'required' => %w[project_id user_ids],
        'properties' => {
          'project_id' => { 'type' => 'integer' },
          'user_ids' => { 'type' => 'array' }
        }
      }
    end
  end
end
