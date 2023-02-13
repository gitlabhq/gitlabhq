# frozen_string_literal: true

class AddUniqueSoftwareLicensePoliciesIndexOnProjectAndScanResultPolicy < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'idx_software_license_policies_unique_on_project_and_scan_policy'

  disable_ddl_transaction!

  def up
    add_concurrent_index :software_license_policies,
      [:project_id, :software_license_id, :scan_result_policy_id],
      unique: true,
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :software_license_policies, INDEX_NAME
  end
end
