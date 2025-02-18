# frozen_string_literal: true

class AddExternalStatusChecksProtectedBranchesProjectIdNotNullConstraint < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  def up
    add_not_null_constraint :external_status_checks_protected_branches, :project_id
  end

  def down
    remove_not_null_constraint :external_status_checks_protected_branches, :project_id
  end
end
