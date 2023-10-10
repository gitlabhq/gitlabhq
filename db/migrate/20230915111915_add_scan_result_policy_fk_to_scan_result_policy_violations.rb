# frozen_string_literal: true

class AddScanResultPolicyFkToScanResultPolicyViolations < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key(
      :scan_result_policy_violations,
      :scan_result_policies,
      column: :scan_result_policy_id,
      on_delete: :cascade)
  end

  def down
    with_lock_retries do
      remove_foreign_key(:scan_result_policy_violations, column: :scan_result_policy_id)
    end
  end
end
