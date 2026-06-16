# frozen_string_literal: true

class DropUniqueIndexBulkImportBatchTrackersIdBatchNumber < Gitlab::Database::Migration[2.3]
  milestone '19.1'
  disable_ddl_transaction!

  TABLE_NAME = :bulk_import_batch_trackers
  INDEX_NAME = 'i_bulk_import_trackers_id_batch_number'
  COLUMNS = %i[tracker_id batch_number]

  def up
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end

  def down
    add_concurrent_index TABLE_NAME, COLUMNS, name: INDEX_NAME, unique: true
  end
end
