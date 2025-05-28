# frozen_string_literal: true

class AddStatusCheckConstraintToBoardLists < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.1'

  def up
    add_check_constraint(
      :lists,
      'list_type != 6 OR num_nonnulls(system_defined_status_identifier, custom_status_id) = 1',
      constraint_name
    )
  end

  def down
    remove_check_constraint :lists, constraint_name
  end

  private

  def constraint_name
    check_constraint_name(:lists, [:system_defined_status_identifier, :custom_status_id], 'exactly_one')
  end
end
