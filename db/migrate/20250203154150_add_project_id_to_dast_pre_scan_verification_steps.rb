# frozen_string_literal: true

class AddProjectIdToDastPreScanVerificationSteps < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def change
    add_column :dast_pre_scan_verification_steps, :project_id, :bigint
  end
end
