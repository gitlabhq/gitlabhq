# frozen_string_literal: true

module PackageMetadata
  class IngestedAdvisoryEvent < ::Gitlab::EventStore::Event
    def schema
      {
        'type' => 'object',
        'properties' => {
          'advisory_id' => { 'type' => 'integer' }
        },
        'required' => %w[advisory_id]
      }
    end
  end
end
