# frozen_string_literal: true

class AddSoftwareLicenseExistenceConstraintToSoftwareLicensePolicies < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  disable_ddl_transaction!

  def up
    add_multi_column_not_null_constraint(:software_license_policies, :software_license_id, :custom_software_license_id)
  end

  def down
    remove_multi_column_not_null_constraint(:software_license_policies,
      :software_license_id,
      :custom_software_license_id)
  end
end
