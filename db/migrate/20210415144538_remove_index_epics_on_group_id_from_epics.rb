# frozen_string_literal: true

class RemoveIndexEpicsOnGroupIdFromEpics < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  INDEX_NAME = 'index_epics_on_group_id'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :epics, INDEX_NAME
  end

  def down
    add_concurrent_index :epics, :group_id, name: INDEX_NAME
  end
end
