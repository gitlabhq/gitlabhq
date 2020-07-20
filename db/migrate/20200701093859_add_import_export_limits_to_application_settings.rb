# frozen_string_literal: true

class AddImportExportLimitsToApplicationSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :application_settings, :project_import_limit, :integer, default: 6, null: false
    add_column :application_settings, :project_export_limit, :integer, default: 6, null: false
    add_column :application_settings, :project_download_export_limit, :integer, default: 1, null: false

    add_column :application_settings, :group_import_limit, :integer, default: 6, null: false
    add_column :application_settings, :group_export_limit, :integer, default: 6, null: false
    add_column :application_settings, :group_download_export_limit, :integer, default: 1, null: false
  end
end
