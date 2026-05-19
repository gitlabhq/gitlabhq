# frozen_string_literal: true

module Organizations
  # Published when a root group is transferred to a different organization.
  # Fired once for the transferred group only - NOT for its descendants.
  # Subscribers are responsible for traversing descendants if needed.
  class GroupTransferredEvent < Gitlab::EventStore::Event
    def schema
      {
        'type' => 'object',
        'required' => %w[group_id old_organization_id new_organization_id],
        'properties' => {
          'group_id' => { 'type' => 'integer' },
          'old_organization_id' => { 'type' => 'integer' },
          'new_organization_id' => { 'type' => 'integer' }
        }
      }
    end
  end
end
