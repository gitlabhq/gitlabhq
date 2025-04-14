# frozen_string_literal: true

class AddTriggeredByIdIndexToResourceIterationEvents < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.11'

  INDEX_NAME = 'i_resource_iteration_events_on_triggered_by_id'

  def up
    add_concurrent_index :resource_iteration_events, :triggered_by_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index :resource_iteration_events, :triggered_by_id, name: INDEX_NAME
  end
end
