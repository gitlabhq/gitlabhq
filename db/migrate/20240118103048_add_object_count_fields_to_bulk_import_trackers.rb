# frozen_string_literal: true

class AddObjectCountFieldsToBulkImportTrackers < Gitlab::Database::Migration[2.2]
  milestone '16.8'

  def change
    add_column :bulk_import_trackers, :source_objects_count, :bigint, null: false, default: 0
    add_column :bulk_import_trackers, :fetched_objects_count, :bigint, null: false, default: 0
    add_column :bulk_import_trackers, :imported_objects_count, :bigint, null: false, default: 0
  end
end
