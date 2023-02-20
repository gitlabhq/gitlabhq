# frozen_string_literal: true

class RemoveUniqueSoftwareLicensePoliciesIndexOnProject < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_software_license_policies_unique_per_project'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :software_license_policies, INDEX_NAME
  end

  def down
    add_concurrent_index :software_license_policies, [:project_id, :software_license_id], unique: true, name: INDEX_NAME
  end
end
