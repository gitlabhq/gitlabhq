# frozen_string_literal: true

class AddIndexUpdatedAtToBulkImportBatchTrackers < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.7'

  INDEX = 'index_bulk_import_batch_trackers_on_tracker_id_and_updated_at'

  def up
    add_concurrent_index :bulk_import_batch_trackers,
      [:tracker_id, :updated_at],
      name: INDEX
  end

  def down
    remove_concurrent_index_by_name :bulk_import_batch_trackers, name: INDEX
  end
end
