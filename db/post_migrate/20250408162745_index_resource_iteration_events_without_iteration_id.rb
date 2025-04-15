# frozen_string_literal: true

class IndexResourceIterationEventsWithoutIterationId < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'tmp_idx_resource_iteration_events_without_iteration'

  disable_ddl_transaction!
  milestone '17.11'

  def up
    add_concurrent_index :resource_iteration_events,
      :id,
      name: INDEX_NAME,
      where: 'iteration_id IS NULL'
  end

  def down
    remove_concurrent_index :resource_iteration_events, :id, name: INDEX_NAME
  end
end
