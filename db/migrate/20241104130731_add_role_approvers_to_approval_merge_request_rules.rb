# frozen_string_literal: true

class AddRoleApproversToApprovalMergeRequestRules < Gitlab::Database::Migration[2.2]
  milestone '17.7'
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_approval_m_r_rules_allowed_role_approvers_valid_entries'

  def up
    add_column :approval_merge_request_rules, :role_approvers, :integer, array: true, default: [], null: false
    check = "(role_approvers = '{}' OR role_approvers <@ ARRAY[20, 30, 40, 50, 60])"
    add_check_constraint :approval_merge_request_rules, check, CONSTRAINT_NAME
  end

  def down
    remove_column :approval_merge_request_rules, :role_approvers
    remove_check_constraint :approval_merge_request_rules, CONSTRAINT_NAME
  end
end
