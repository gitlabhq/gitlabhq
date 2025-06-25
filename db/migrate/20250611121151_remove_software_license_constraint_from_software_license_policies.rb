# frozen_string_literal: true

class RemoveSoftwareLicenseConstraintFromSoftwareLicensePolicies < Gitlab::Database::Migration[2.3]
  milestone '18.2'
  disable_ddl_transaction!

  def up
    remove_multi_column_not_null_constraint(:software_license_policies,
      :software_license_id,
      :custom_software_license_id)
  end

  def down
    # no-op
  end
end
