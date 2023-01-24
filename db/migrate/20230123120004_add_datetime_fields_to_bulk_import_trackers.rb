# frozen_string_literal: true

class AddDatetimeFieldsToBulkImportTrackers < Gitlab::Database::Migration[2.1]
  def up
    add_column :bulk_import_trackers, :created_at, :datetime_with_timezone, null: true
    add_column :bulk_import_trackers, :updated_at, :datetime_with_timezone, null: true
  end

  def down
    remove_column :bulk_import_trackers, :created_at
    remove_column :bulk_import_trackers, :updated_at
  end
end
