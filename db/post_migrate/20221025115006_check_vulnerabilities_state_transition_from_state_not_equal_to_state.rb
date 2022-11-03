# frozen_string_literal: true

class CheckVulnerabilitiesStateTransitionFromStateNotEqualToState < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    add_check_constraint(:vulnerability_state_transitions, '(from_state != to_state)', constraint_name)
  end

  def down
    remove_check_constraint(:vulnerability_state_transitions, constraint_name)
  end

  private

  def constraint_name
    check_constraint_name('vulnerability_state_transitions', 'fully_qualified_table_name', 'state_not_equal')
  end
end
