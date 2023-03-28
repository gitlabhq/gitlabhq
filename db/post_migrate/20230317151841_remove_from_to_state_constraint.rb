# frozen_string_literal: true

class RemoveFromToStateConstraint < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    constraint_name = check_constraint_name(
      'vulnerability_state_transitions',
      'fully_qualified_table_name',
      'state_not_equal')
    remove_check_constraint(:vulnerability_state_transitions, constraint_name)
  end

  def down
    constraint_name = check_constraint_name(
      'vulnerability_state_transitions',
      'fully_qualified_table_name',
      'state_not_equal')
    add_check_constraint(:vulnerability_state_transitions, '(from_state != to_state)', constraint_name)
  end
end
