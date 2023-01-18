# frozen_string_literal: true

class AddIndexForProjectActivityEvents < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_events_for_project_activity'

  def up
    add_concurrent_index :events, %i[project_id target_type action id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :events, INDEX_NAME
  end
end
