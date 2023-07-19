# frozen_string_literal: true

class AddIndexToPoolRepositories < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  TABLE_NAME = :pool_repositories
  OLD_INDEX_NAME = :index_pool_repositories_on_disk_path
  NEW_INDEX_NAME = :unique_pool_repositories_on_disk_path_and_shard_id

  def up
    add_concurrent_index(TABLE_NAME, [:disk_path, :shard_id], name: NEW_INDEX_NAME, unique: true)

    remove_concurrent_index_by_name(TABLE_NAME, OLD_INDEX_NAME)
  end

  def down
    add_concurrent_index(TABLE_NAME, [:disk_path], name: OLD_INDEX_NAME, unique: true)

    remove_concurrent_index_by_name(TABLE_NAME, NEW_INDEX_NAME)
  end
end
