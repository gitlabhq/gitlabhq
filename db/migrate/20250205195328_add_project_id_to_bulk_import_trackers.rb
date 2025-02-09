# frozen_string_literal: true

class AddProjectIdToBulkImportTrackers < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def change
    add_column :bulk_import_trackers, :project_id, :bigint
  end
end
