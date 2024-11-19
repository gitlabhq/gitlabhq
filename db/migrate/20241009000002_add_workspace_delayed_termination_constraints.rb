# frozen_string_literal: true

class AddWorkspaceDelayedTerminationConstraints < Gitlab::Database::Migration[2.2]
  milestone "17.6"
  disable_ddl_transaction!

  TABLE_NAME = :workspaces_agent_configs

  def constraint_1_name
    check_constraint_name TABLE_NAME,
      "max_active_hours_before_stop and max_stopped_hours_before_termination", "max_total_size_1_year"
  end

  def constraint_2_name
    check_constraint_name TABLE_NAME, :max_active_hours_before_stop, "min_size_0"
  end

  def constraint_3_name
    check_constraint_name TABLE_NAME, :max_stopped_hours_before_termination, "min_size_0"
  end

  def up
    add_check_constraint TABLE_NAME,
      "(max_active_hours_before_stop + max_stopped_hours_before_termination) <= 8760", constraint_1_name
    add_check_constraint TABLE_NAME, "max_active_hours_before_stop > 0", constraint_2_name
    add_check_constraint TABLE_NAME, "max_stopped_hours_before_termination > 0", constraint_3_name
  end

  def down
    remove_check_constraint TABLE_NAME, constraint_1_name
    remove_check_constraint TABLE_NAME, constraint_2_name
    remove_check_constraint TABLE_NAME, constraint_3_name
  end
end
