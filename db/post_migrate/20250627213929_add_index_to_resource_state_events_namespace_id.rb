# frozen_string_literal: true

class AddIndexToResourceStateEventsNamespaceId < Gitlab::Database::Migration[2.3]
  NAME = 'index_resource_state_events_on_namespace_id'

  milestone '18.2'
  disable_ddl_transaction!

  def up
    add_concurrent_index :resource_state_events, :namespace_id, name: NAME
  end

  def down
    remove_concurrent_index_by_name :resource_state_events, NAME
  end
end
