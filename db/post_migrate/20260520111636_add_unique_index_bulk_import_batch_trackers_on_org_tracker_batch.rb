# frozen_string_literal: true

class AddUniqueIndexBulkImportBatchTrackersOnOrgTrackerBatch < Gitlab::Database::Migration[2.3]
  milestone '19.1'
  disable_ddl_transaction!

  TABLE_NAME = :bulk_import_batch_trackers
  INDEX_NAME = 'idx_bulk_import_batch_trackers_on_tracker_batch_org_uniq'
  COLUMNS = %i[tracker_id batch_number organization_id]

  def up
    add_concurrent_index TABLE_NAME, COLUMNS, name: INDEX_NAME, unique: true
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end
