# frozen_string_literal: true

class AddAsyncIndexForGroupActivityEvents < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'index_events_for_group_activity'

  def up
    prepare_async_index :events, %I[group_id target_type action id], name: INDEX_NAME, where: 'group_id IS NOT NULL'
  end

  def down
    unprepare_async_index :events, %I[group_id target_type action id], name: INDEX_NAME, where: 'group_id IS NOT NULL'
  end
end
