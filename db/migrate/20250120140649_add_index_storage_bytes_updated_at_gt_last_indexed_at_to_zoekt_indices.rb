# frozen_string_literal: true

class AddIndexStorageBytesUpdatedAtGtLastIndexedAtToZoektIndices < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  INDEX_NAME = 'idx_last_indexed_at_gt_used_storage_bytes_updated_at'
  TABLE_NAME = 'zoekt_indices'

  def up
    where = 'last_indexed_at >= used_storage_bytes_updated_at'
    add_concurrent_index TABLE_NAME, [:last_indexed_at, :used_storage_bytes_updated_at], name: INDEX_NAME, where: where
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end
