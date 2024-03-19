# frozen_string_literal: true

class AddViolationDataToScanResultPolicyViolations < Gitlab::Database::Migration[2.2]
  enable_lock_retries!
  milestone '16.10'

  def change
    add_column :scan_result_policy_violations, :violation_data, :jsonb, null: true
  end
end
