# frozen_string_literal: true

class RemoveGroupIdFromCdVersionSetEntries < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.4'

  TABLE_NAME = :cd_version_set_entries
  INDEX_NAME = :index_cd_version_set_entries_on_group_id

  def up
    return unless table_exists?(TABLE_NAME)

    with_lock_retries do
      remove_column TABLE_NAME, :group_id, if_exists: true
    end
  end

  def down
    with_lock_retries do
      add_column TABLE_NAME, :group_id, :bigint unless column_exists?(TABLE_NAME, :group_id)
    end

    add_concurrent_index TABLE_NAME, :group_id, name: INDEX_NAME
  end
end
