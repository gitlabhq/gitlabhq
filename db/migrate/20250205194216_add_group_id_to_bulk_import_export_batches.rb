# frozen_string_literal: true

class AddGroupIdToBulkImportExportBatches < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def change
    add_column :bulk_import_export_batches, :group_id, :bigint
  end
end
