# frozen_string_literal: true

class AddMergeRequestsApprovalRulesMultiColumnNotNullConstraint < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  disable_ddl_transaction!

  def up
    add_multi_column_not_null_constraint(:merge_requests_approval_rules, :group_id, :project_id)
  end

  def down
    remove_multi_column_not_null_constraint(:merge_requests_approval_rules, :group_id, :project_id)
  end
end
