# frozen_string_literal: true

class DropIndexEventsOnGroupIdPartial < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  INDEX_NAME = 'index_events_on_group_id_partial'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :events, name: INDEX_NAME
  end

  def down
    add_concurrent_index :events, :group_id, name: INDEX_NAME, where: 'group_id IS NOT NULL'
  end
end
