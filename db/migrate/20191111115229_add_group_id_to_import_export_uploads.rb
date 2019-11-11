# frozen_string_literal: true

class AddGroupIdToImportExportUploads < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column :import_export_uploads, :group_id, :bigint
  end
end
