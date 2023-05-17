# frozen_string_literal: true

class AddBatchedColumnToBulkImportTrackers < Gitlab::Database::Migration[2.1]
  def change
    add_column :bulk_import_trackers, :batched, :boolean, default: false
  end
end
