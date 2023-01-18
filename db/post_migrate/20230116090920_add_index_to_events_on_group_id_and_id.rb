# frozen_string_literal: true

class AddIndexToEventsOnGroupIdAndId < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_events_on_group_id_and_id'

  def up
    add_concurrent_index :events, %i[group_id id], name: INDEX_NAME, where: 'group_id IS NOT NULL'
  end

  def down
    remove_concurrent_index_by_name :events, INDEX_NAME
  end
end
