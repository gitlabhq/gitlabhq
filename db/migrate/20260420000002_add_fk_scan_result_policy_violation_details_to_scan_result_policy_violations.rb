# frozen_string_literal: true

class AddFkScanResultPolicyViolationDetailsToScanResultPolicyViolations < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.0'

  def up
    add_concurrent_foreign_key :scan_result_policy_violation_details,
      :scan_result_policy_violations,
      column: :scan_result_policy_violation_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :scan_result_policy_violation_details,
        column: :scan_result_policy_violation_id
    end
  end
end
