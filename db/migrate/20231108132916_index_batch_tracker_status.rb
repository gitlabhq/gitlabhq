# frozen_string_literal: true

class IndexBatchTrackerStatus < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.7'

  INDEX_NAME = 'index_batch_trackers_on_tracker_id_status'

  def up
    add_concurrent_index :bulk_import_batch_trackers, [:tracker_id, :status], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :bulk_import_batch_trackers, INDEX_NAME
  end
end
