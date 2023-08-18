# frozen_string_literal: true

module ProjectAuthorizations
  class AuthorizationsChangedEvent < ::Gitlab::EventStore::Event
    def schema
      {
        'type' => 'object',
        'required' => %w[project_id],
        'properties' => {
          'project_id' => { 'type' => 'integer' }
        }
      }
    end
  end
end
