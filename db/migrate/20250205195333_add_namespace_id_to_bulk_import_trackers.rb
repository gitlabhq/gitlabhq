# frozen_string_literal: true

class AddNamespaceIdToBulkImportTrackers < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def change
    add_column :bulk_import_trackers, :namespace_id, :bigint
  end
end
