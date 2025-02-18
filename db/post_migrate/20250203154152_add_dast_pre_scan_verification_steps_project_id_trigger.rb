# frozen_string_literal: true

class AddDastPreScanVerificationStepsProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def up
    install_sharding_key_assignment_trigger(
      table: :dast_pre_scan_verification_steps,
      sharding_key: :project_id,
      parent_table: :dast_pre_scan_verifications,
      parent_sharding_key: :project_id,
      foreign_key: :dast_pre_scan_verification_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :dast_pre_scan_verification_steps,
      sharding_key: :project_id,
      parent_table: :dast_pre_scan_verifications,
      parent_sharding_key: :project_id,
      foreign_key: :dast_pre_scan_verification_id
    )
  end
end
