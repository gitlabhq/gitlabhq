# frozen_string_literal: true

class AddBulkImportExportBatches < Gitlab::Database::Migration[2.1]
  def up
    create_table :bulk_import_export_batches do |t|
      t.references :export, index: true, null: false, foreign_key: {
        to_table: :bulk_import_exports, on_delete: :cascade
      }
      t.timestamps_with_timezone null: false
      t.integer :status, limit: 2, null: false, default: 0
      t.integer :batch_number, null: false, default: 0
      t.integer :objects_count, null: false, default: 0
      t.text :error, limit: 255
      t.index [:export_id, :batch_number], unique: true, name: 'i_bulk_import_export_batches_id_batch_number'
    end
  end

  def down
    drop_table :bulk_import_export_batches
  end
end
