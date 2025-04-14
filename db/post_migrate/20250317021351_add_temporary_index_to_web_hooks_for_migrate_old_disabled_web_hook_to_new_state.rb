# frozen_string_literal: true

class AddTemporaryIndexToWebHooksForMigrateOldDisabledWebHookToNewState < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  INDEX_NAME = 'tmp_index_web_hooks_on_disabled_until_recent_failures'
  TABLE = :web_hooks
  COLUMNS = [:id, :recent_failures, :disabled_until]

  disable_ddl_transaction!

  def up
    add_concurrent_index TABLE, COLUMNS, where: 'disabled_until is NULL', name: INDEX_NAME

    connection.execute("ANALYZE #{TABLE}")
  end

  def down
    remove_concurrent_index_by_name TABLE, INDEX_NAME
  end
end
