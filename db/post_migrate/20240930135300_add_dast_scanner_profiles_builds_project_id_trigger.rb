# frozen_string_literal: true

class AddDastScannerProfilesBuildsProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def up
    install_sharding_key_assignment_trigger(
      table: :dast_scanner_profiles_builds,
      sharding_key: :project_id,
      parent_table: :dast_scanner_profiles,
      parent_sharding_key: :project_id,
      foreign_key: :dast_scanner_profile_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :dast_scanner_profiles_builds,
      sharding_key: :project_id,
      parent_table: :dast_scanner_profiles,
      parent_sharding_key: :project_id,
      foreign_key: :dast_scanner_profile_id
    )
  end
end
