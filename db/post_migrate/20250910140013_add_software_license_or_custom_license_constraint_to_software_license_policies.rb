# frozen_string_literal: true

class AddSoftwareLicenseOrCustomLicenseConstraintToSoftwareLicensePolicies < Gitlab::Database::Migration[2.3]
  milestone '18.4'
  disable_ddl_transaction!

  def up
    add_multi_column_not_null_constraint(:software_license_policies, :software_license_spdx_identifier,
      :custom_software_license_id)
  end

  def down
    remove_multi_column_not_null_constraint(:software_license_policies,
      :software_license_spdx_identifier,
      :custom_software_license_id)
  end
end
