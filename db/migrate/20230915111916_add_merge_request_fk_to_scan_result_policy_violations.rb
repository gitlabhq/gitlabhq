# frozen_string_literal: true

class AddMergeRequestFkToScanResultPolicyViolations < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key(
      :scan_result_policy_violations,
      :merge_requests,
      column: :merge_request_id,
      on_delete: :cascade)
  end

  def down
    with_lock_retries do
      remove_foreign_key(:scan_result_policy_violations, column: :merge_request_id)
    end
  end
end
