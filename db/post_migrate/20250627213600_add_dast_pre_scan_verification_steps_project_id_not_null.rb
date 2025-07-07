# frozen_string_literal: true

class AddDastPreScanVerificationStepsProjectIdNotNull < Gitlab::Database::Migration[2.3]
  milestone '18.2'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :dast_pre_scan_verification_steps, :project_id
  end

  def down
    remove_not_null_constraint :dast_pre_scan_verification_steps, :project_id
  end
end
