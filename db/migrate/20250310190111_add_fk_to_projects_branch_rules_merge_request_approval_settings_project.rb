# frozen_string_literal: true

class AddFkToProjectsBranchRulesMergeRequestApprovalSettingsProject < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.10'

  def up
    add_concurrent_foreign_key(
      :projects_branch_rules_merge_request_approval_settings,
      :projects, column: :project_id,
      on_delete: :cascade,
      reverse_lock_order: true
    )
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(
        :projects_branch_rules_merge_request_approval_settings,
        column: :project_id,
        reverse_lock_order: true
      )
    end
  end
end
