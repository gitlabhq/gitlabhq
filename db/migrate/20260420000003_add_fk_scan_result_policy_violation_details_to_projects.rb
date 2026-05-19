# frozen_string_literal: true

class AddFkScanResultPolicyViolationDetailsToProjects < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.0'

  def up
    add_concurrent_foreign_key :scan_result_policy_violation_details,
      :projects,
      column: :project_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :scan_result_policy_violation_details, column: :project_id
    end
  end
end
