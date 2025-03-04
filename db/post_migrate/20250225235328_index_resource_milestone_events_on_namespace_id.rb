# frozen_string_literal: true

class IndexResourceMilestoneEventsOnNamespaceId < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'idx_resource_milestone_events_on_namespace_id'

  disable_ddl_transaction!
  milestone '17.10'

  def up
    add_concurrent_index :resource_milestone_events,
      :namespace_id,
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index :resource_milestone_events, :namespace_id, name: INDEX_NAME
  end
end
