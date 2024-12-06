# frozen_string_literal: true

class RemoveSoftwareLicenseExistenceConstraintToSoftwareLicensePolicies < Gitlab::Database::Migration[2.2]
  milestone '17.7'
  disable_ddl_transaction!

  def up
    remove_multi_column_not_null_constraint(:software_license_policies,
      :software_license_id,
      :custom_software_license_id)

    add_multi_column_not_null_constraint(:software_license_policies,
      :software_license_id,
      :custom_software_license_id,
      operator: '>',
      limit: 0)
  end

  def down
    # remove the check with > 0
    remove_multi_column_not_null_constraint(:software_license_policies,
      :software_license_id,
      :custom_software_license_id)

    # adds back the current check = 1
    add_multi_column_not_null_constraint(:software_license_policies, :software_license_id, :custom_software_license_id)
  end
end
