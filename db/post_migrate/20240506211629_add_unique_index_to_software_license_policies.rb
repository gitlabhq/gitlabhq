# frozen_string_literal: true

class AddUniqueIndexToSoftwareLicensePolicies < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  INDEX_NAME = 'idx_software_license_policies_unique_on_custom_license_project'

  disable_ddl_transaction!

  def up
    add_concurrent_index :software_license_policies,
      [:project_id, :custom_software_license_id, :scan_result_policy_id], name: INDEX_NAME, unique: true
  end

  def down
    remove_concurrent_index_by_name :software_license_policies, name: INDEX_NAME
  end
end
