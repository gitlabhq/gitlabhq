# frozen_string_literal: true

class AddMutuallyExclusiveProvisionedByConstraintToUserDetails < Gitlab::Database::Migration[2.3]
  milestone '18.10'
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_user_details_provisioned_by_mutually_exclusive'

  def up
    add_check_constraint(
      :user_details,
      'num_nonnulls(provisioned_by_group_id, provisioned_by_project_id) <= 1',
      CONSTRAINT_NAME
    )
  end

  def down
    remove_check_constraint(:user_details, CONSTRAINT_NAME)
  end
end
