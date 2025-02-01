# frozen_string_literal: true

class AddIndexToZoektIndexUsedStorageBytesUpdatedAt < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  OLD_INDEX_NAME = 'idx_last_indexed_at_gt_used_storage_bytes_updated_at'
  NEW_INDEX_NAME = 'idx_zoekt_last_indexed_at_gt_used_storage_bytes_updated_at'
  WHERE = 'last_indexed_at >= used_storage_bytes_updated_at'
  TABLE_NAME = 'zoekt_indices'

  def up
    remove_concurrent_index_by_name TABLE_NAME, OLD_INDEX_NAME
    add_concurrent_index TABLE_NAME, :used_storage_bytes_updated_at, name: NEW_INDEX_NAME, where: WHERE
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, NEW_INDEX_NAME
    add_concurrent_index TABLE_NAME,
      [:last_indexed_at, :used_storage_bytes_updated_at], name: OLD_INDEX_NAME, where: WHERE
  end
end
