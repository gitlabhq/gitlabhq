# frozen_string_literal: true

class AddProjectIdToDastScannerProfilesBuilds < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    add_column :dast_scanner_profiles_builds, :project_id, :bigint
  end
end
