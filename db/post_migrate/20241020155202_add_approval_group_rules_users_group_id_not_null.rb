# frozen_string_literal: true

class AddApprovalGroupRulesUsersGroupIdNotNull < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :approval_group_rules_users, :group_id
  end

  def down
    remove_not_null_constraint :approval_group_rules_users, :group_id
  end
end
