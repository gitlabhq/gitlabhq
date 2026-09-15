# frozen_string_literal: true

class AddGovernPoliciesFkToGovernPolicyViolations < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.4'

  def up
    add_concurrent_foreign_key :govern_policy_violations, :govern_policies,
      column: :govern_policy_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :govern_policy_violations, column: :govern_policy_id
    end
  end
end
