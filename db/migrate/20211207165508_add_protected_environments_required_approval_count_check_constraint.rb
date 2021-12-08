# frozen_string_literal: true

class AddProtectedEnvironmentsRequiredApprovalCountCheckConstraint < Gitlab::Database::Migration[1.0]
  CONSTRAINT_NAME = 'protected_environments_required_approval_count_positive'

  disable_ddl_transaction!

  def up
    add_check_constraint :protected_environments, 'required_approval_count >= 0', CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :protected_environments, CONSTRAINT_NAME
  end
end
