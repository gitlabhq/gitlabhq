# frozen_string_literal: true

class AddCustomSoftwareLicenseFkToSoftwareLicensePolicies < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  disable_ddl_transaction!

  INDEX_NAME = 'i_software_license_policies_on_custom_software_license_id'

  def up
    add_concurrent_index :software_license_policies, :custom_software_license_id, name: INDEX_NAME
    add_concurrent_foreign_key :software_license_policies, :custom_software_licenses,
      column: :custom_software_license_id, on_delete: :cascade
  end

  def down
    remove_foreign_key_if_exists :software_license_policies, column: :custom_software_license_id
    remove_concurrent_index_by_name :software_license_policies, INDEX_NAME
  end
end
