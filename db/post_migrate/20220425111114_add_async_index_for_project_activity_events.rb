# frozen_string_literal: true

class AddAsyncIndexForProjectActivityEvents < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'index_events_for_project_activity'

  def up
    prepare_async_index :events, %I[project_id target_type action id], name: INDEX_NAME
  end

  def down
    unprepare_async_index :events, %I[project_id target_type action id], name: INDEX_NAME
  end
end
