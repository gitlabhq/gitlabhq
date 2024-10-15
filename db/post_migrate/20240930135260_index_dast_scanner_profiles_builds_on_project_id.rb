# frozen_string_literal: true

class IndexDastScannerProfilesBuildsOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.5'
  disable_ddl_transaction!

  INDEX_NAME = 'index_dast_scanner_profiles_builds_on_project_id'

  def up
    add_concurrent_index :dast_scanner_profiles_builds, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :dast_scanner_profiles_builds, INDEX_NAME
  end
end
