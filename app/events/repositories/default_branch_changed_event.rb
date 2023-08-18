# frozen_string_literal: true

module Repositories
  class DefaultBranchChangedEvent < ::Gitlab::EventStore::Event
    def schema
      {
        'type' => 'object',
        'properties' => {
          'container_id' => { 'type' => 'integer' },
          'container_type' => { 'type' => 'string' }
        },
        'required' => %w[container_id container_type]
      }
    end
  end
end
