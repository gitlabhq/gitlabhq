# frozen_string_literal: true

class RemoveIndexEventsOnProjectIdAndIdDescOnMergedAction < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_events_on_project_id_and_id_desc_on_merged_action'

  disable_ddl_transaction!

  def up
    remove_concurrent_index(:events, [:project_id, :id], order: { id: :desc },
      where: "action = 7", name: INDEX_NAME)
  end

  def down
    add_concurrent_index(:events, [:project_id, :id], order: { id: :desc },
      where: "action = 7", name: INDEX_NAME)
  end
end
