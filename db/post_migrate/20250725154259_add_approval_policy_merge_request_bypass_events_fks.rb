# frozen_string_literal: true

class AddApprovalPolicyMergeRequestBypassEventsFks < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.3'

  def up
    add_concurrent_foreign_key :approval_policy_merge_request_bypass_events, :merge_requests,
      column: :merge_request_id,
      on_delete: :cascade
    add_concurrent_foreign_key :approval_policy_merge_request_bypass_events, :security_policies,
      column: :security_policy_id,
      on_delete: :cascade
    add_concurrent_foreign_key :approval_policy_merge_request_bypass_events, :users, column: :user_id,
      on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key :approval_policy_merge_request_bypass_events, column: :merge_request_id
    end
    with_lock_retries do
      remove_foreign_key :approval_policy_merge_request_bypass_events, column: :security_policy_id
    end
    with_lock_retries do
      remove_foreign_key :approval_policy_merge_request_bypass_events, column: :user_id
    end
  end
end
