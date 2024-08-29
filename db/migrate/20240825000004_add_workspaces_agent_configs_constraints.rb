# frozen_string_literal: true

class AddWorkspacesAgentConfigsConstraints < Gitlab::Database::Migration[2.2]
  milestone "17.4"
  disable_ddl_transaction!

  TABLE_NAME = :workspaces_agent_configs

  def constraint_1_name
    check_constraint_name TABLE_NAME, :default_max_hours_before_termination, "max_size_1_year"
  end

  def constraint_2_name
    check_constraint_name TABLE_NAME, :max_hours_before_termination_limit, "max_size_1_year"
  end

  def up
    add_check_constraint TABLE_NAME, "default_max_hours_before_termination <= 8760", constraint_1_name
    add_check_constraint TABLE_NAME, "max_hours_before_termination_limit <= 8760", constraint_2_name
  end

  def down
    remove_check_constraint TABLE_NAME, constraint_1_name
    remove_check_constraint TABLE_NAME, constraint_2_name
  end
end
