# frozen_string_literal: true

class RemoveIndexOnAutoStopIn < Gitlab::Database::Migration[1.0]
  TABLE = :environments
  INDEX_NAME = 'index_environments_on_auto_stop_at'
  COLUMN = :auto_stop_at

  disable_ddl_transaction!

  def up
    remove_concurrent_index TABLE, COLUMN, where: 'auto_stop_at IS NOT NULL', name: INDEX_NAME
  end

  def down
    add_concurrent_index TABLE, COLUMN, where: 'auto_stop_at IS NOT NULL', name: INDEX_NAME
  end
end
