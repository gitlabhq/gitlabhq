# frozen_string_literal: true

class RemoveSoftwareLicensePoliciesSoftwareLicenseIdColumn < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.3'

  UNIQUE_INDEX_NAME = 'idx_software_license_policies_unique_on_project_and_scan_policy'
  INDEX_NAME = 'index_software_license_policies_on_software_license_id'

  def up
    with_lock_retries do
      remove_column :software_license_policies, :software_license_id
    end
  end

  def down
    with_lock_retries do
      add_column :software_license_policies,
        :software_license_id,
        :bigint,
        null: true,
        if_not_exists: true
    end

    add_concurrent_foreign_key :software_license_policies, :software_licenses,
      column: :software_license_id, on_delete: :cascade

    add_concurrent_index :software_license_policies,
      [:project_id, :software_license_id, :scan_result_policy_id],
      name: UNIQUE_INDEX_NAME, unique: true

    add_concurrent_index :software_license_policies, :software_license_id, name: INDEX_NAME
  end
end
