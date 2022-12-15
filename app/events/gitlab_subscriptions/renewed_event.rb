# frozen_string_literal: true

module GitlabSubscriptions
  class RenewedEvent < Gitlab::EventStore::Event
    def schema
      {
        'type' => 'object',
        'required' => %w[
          namespace_id
        ],
        'properties' => {
          'namespace_id' => { 'type' => 'integer' }
        }
      }
    end
  end
end
