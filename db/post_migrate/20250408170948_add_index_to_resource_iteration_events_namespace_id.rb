# frozen_string_literal: true

class AddIndexToResourceIterationEventsNamespaceId < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'idx_resource_iteration_events_on_namespace_id'

  disable_ddl_transaction!
  milestone '17.11'

  def up
    add_concurrent_index :resource_iteration_events, :namespace_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index :resource_iteration_events, :namespace_id, name: INDEX_NAME
  end
end
