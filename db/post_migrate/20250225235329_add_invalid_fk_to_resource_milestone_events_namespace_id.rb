# frozen_string_literal: true

class AddInvalidFkToResourceMilestoneEventsNamespaceId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.10'

  def up
    add_concurrent_foreign_key :resource_milestone_events,
      :namespaces,
      column: :namespace_id,
      validate: false,
      reverse_lock_order: true
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :resource_milestone_events, column: :namespace_id
    end
  end
end
