# frozen_string_literal: true

class AddArchivedToSecurityScanProfilesProjects < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  def up
    add_column :security_scan_profiles_projects, :archived, :boolean, default: false, null: false
  end

  def down
    remove_column :security_scan_profiles_projects, :archived
  end
end
