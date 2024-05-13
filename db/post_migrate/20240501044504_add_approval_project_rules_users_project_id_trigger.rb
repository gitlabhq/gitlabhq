# frozen_string_literal: true

class AddApprovalProjectRulesUsersProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  def up
    install_sharding_key_assignment_trigger(
      table: :approval_project_rules_users,
      sharding_key: :project_id,
      parent_table: :approval_project_rules,
      parent_sharding_key: :project_id,
      foreign_key: :approval_project_rule_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :approval_project_rules_users,
      sharding_key: :project_id,
      parent_table: :approval_project_rules,
      parent_sharding_key: :project_id,
      foreign_key: :approval_project_rule_id
    )
  end
end
