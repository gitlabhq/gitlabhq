# frozen_string_literal: true

module Organizations
  # Published when an organization transitions from `unconfirmed` to `confirmed`.
  class ConfirmedEvent < Gitlab::EventStore::Event
    def schema
      {
        'type' => 'object',
        'required' => %w[organization_id],
        'properties' => {
          'organization_id' => { 'type' => 'integer' }
        }
      }
    end
  end
end
