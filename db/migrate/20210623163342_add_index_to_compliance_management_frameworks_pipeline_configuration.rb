# frozen_string_literal: true

class AddIndexToComplianceManagementFrameworksPipelineConfiguration < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  INDEX_NAME = 'index_compliance_frameworks_id_where_frameworks_not_null'

  def up
    add_concurrent_index :compliance_management_frameworks, :id, name: INDEX_NAME, where: 'pipeline_configuration_full_path IS NOT NULL'
  end

  def down
    remove_concurrent_index_by_name :compliance_management_frameworks, INDEX_NAME
  end
end
