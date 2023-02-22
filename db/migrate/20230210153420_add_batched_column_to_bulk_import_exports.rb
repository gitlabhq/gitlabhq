# frozen_string_literal: true

class AddBatchedColumnToBulkImportExports < Gitlab::Database::Migration[2.1]
  def change
    add_column :bulk_import_exports, :batched, :boolean, null: false, default: false
    add_column :bulk_import_exports, :batches_count, :integer, null: false, default: 0
    add_column :bulk_import_exports, :total_objects_count, :integer, null: false, default: 0
  end
end
