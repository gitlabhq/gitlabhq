# frozen_string_literal: true

class AddCreatedAtIndexToComplianceManagementFrameworks < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = "i_compliance_frameworks_on_id_and_created_at"

  def up
    add_concurrent_index :compliance_management_frameworks,
                         [:id, :created_at, :pipeline_configuration_full_path],
                         name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :compliance_management_frameworks, INDEX_NAME
  end
end
