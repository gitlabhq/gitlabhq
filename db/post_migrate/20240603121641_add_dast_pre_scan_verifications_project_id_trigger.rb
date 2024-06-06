# frozen_string_literal: true

class AddDastPreScanVerificationsProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def up
    install_sharding_key_assignment_trigger(
      table: :dast_pre_scan_verifications,
      sharding_key: :project_id,
      parent_table: :dast_profiles,
      parent_sharding_key: :project_id,
      foreign_key: :dast_profile_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :dast_pre_scan_verifications,
      sharding_key: :project_id,
      parent_table: :dast_profiles,
      parent_sharding_key: :project_id,
      foreign_key: :dast_profile_id
    )
  end
end
