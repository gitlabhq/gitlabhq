# frozen_string_literal: true

module Projects
  class ReleasePublishedEvent < ::Gitlab::EventStore::Event
    def schema
      {
        'type' => 'object',
        'properties' => {
          'release_id' => { 'type' => 'integer' }
        },
        'required' => %w[release_id]
      }
    end
  end
end
