# frozen_string_literal: true

class AddAsyncIndexToEventsOnGroupIdAndId < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'index_events_on_group_id_and_id'

  def up
    prepare_async_index :events, %I[group_id id], name: INDEX_NAME, where: 'group_id IS NOT NULL'
  end

  def down
    unprepare_async_index :events, %I[group_id id], name: INDEX_NAME, where: 'group_id IS NOT NULL'
  end
end
