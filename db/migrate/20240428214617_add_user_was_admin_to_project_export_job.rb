# frozen_string_literal: true

class AddUserWasAdminToProjectExportJob < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  def up
    add_column :project_export_jobs, :exported_by_admin, :boolean, default: false
  end

  def down
    remove_column :project_export_jobs, :exported_by_admin
  end
end
