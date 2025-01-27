# frozen_string_literal: true

class AddApprovalMergeRequestRuleSourcesProjectIdNotNullConstraint < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  def up
    add_not_null_constraint :approval_merge_request_rule_sources, :project_id, validate: false
  end

  def down
    remove_not_null_constraint :approval_merge_request_rule_sources, :project_id
  end
end
