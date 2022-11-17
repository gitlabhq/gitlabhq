# frozen_string_literal: true

class AddGroupOrProjectConstraintInProtectedBranches < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'protected_branches_project_id_namespace_id_any_not_null'

  def up
    constraint = <<~CONSTRAINT
      (project_id IS NULL) <> (namespace_id IS NULL)
    CONSTRAINT
    add_check_constraint :protected_branches, constraint, CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :protected_branches, CONSTRAINT_NAME
  end
end
