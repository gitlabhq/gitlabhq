# frozen_string_literal: true

class RemoveAgentConfigMaxHoursBeforeTerminationColumns < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.10'
  TABLE_NAME = :workspaces_agent_configs

  def constraint_1_name
    check_constraint_name TABLE_NAME, :default_max_hours_before_termination, "max_size_1_year"
  end

  def constraint_2_name
    check_constraint_name TABLE_NAME, :max_hours_before_termination_limit, "max_size_1_year"
  end

  def up
    remove_column TABLE_NAME, :default_max_hours_before_termination
    remove_column TABLE_NAME, :max_hours_before_termination_limit
  end

  def down
    add_column(TABLE_NAME, :max_hours_before_termination_limit, :smallint, null: false, default: 120,
      if_not_exists: true)
    add_column(TABLE_NAME, :default_max_hours_before_termination, :smallint, null: false, default: 24,
      if_not_exists: true)

    add_check_constraint TABLE_NAME, "default_max_hours_before_termination <= 8760", constraint_1_name
    add_check_constraint TABLE_NAME, "max_hours_before_termination_limit <= 8760", constraint_2_name
  end
end
