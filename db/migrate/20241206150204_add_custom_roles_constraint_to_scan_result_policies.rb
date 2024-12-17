# frozen_string_literal: true

class AddCustomRolesConstraintToScanResultPolicies < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.7'

  CONSTRAINT_NAME = 'custom_roles_array_check'

  def up
    add_check_constraint(:scan_result_policies, "ARRAY_POSITION(custom_roles, null) IS null", CONSTRAINT_NAME)
  end

  def down
    remove_check_constraint :scan_result_policies, CONSTRAINT_NAME
  end
end
