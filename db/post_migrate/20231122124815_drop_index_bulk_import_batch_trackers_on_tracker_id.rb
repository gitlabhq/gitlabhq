# frozen_string_literal: true

class DropIndexBulkImportBatchTrackersOnTrackerId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.7'

  INDEX_NAME = :index_bulk_import_batch_trackers_on_tracker_id
  TABLE_NAME = :bulk_import_batch_trackers

  def up
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end

  def down
    add_concurrent_index TABLE_NAME, :tracker_id, name: INDEX_NAME
  end
end
