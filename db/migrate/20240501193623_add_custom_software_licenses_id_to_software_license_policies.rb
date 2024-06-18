# frozen_string_literal: true

class AddCustomSoftwareLicensesIdToSoftwareLicensePolicies < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def up
    add_column :software_license_policies,
      :custom_software_license_id,
      :bigint,
      null: true,
      if_not_exists: true
  end

  def down
    remove_column :software_license_policies, :custom_software_license_id, if_exists: true
  end
end
