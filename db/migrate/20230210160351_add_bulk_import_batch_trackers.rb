# frozen_string_literal: true

class AddBulkImportBatchTrackers < Gitlab::Database::Migration[2.1]
  def up
    create_table :bulk_import_batch_trackers do |t|
      t.references :tracker, index: true, null: false, foreign_key: {
        to_table: :bulk_import_trackers, on_delete: :cascade
      }
      t.timestamps_with_timezone null: false
      t.integer :status, limit: 2, null: false, default: 0
      t.integer :batch_number, null: false, default: 0
      t.integer :fetched_objects_count, null: false, default: 0
      t.integer :imported_objects_count, null: false, default: 0
      t.text :error, limit: 255
      t.index [:tracker_id, :batch_number], unique: true, name: 'i_bulk_import_trackers_id_batch_number'
    end
  end

  def down
    drop_table :bulk_import_batch_trackers
  end
end
