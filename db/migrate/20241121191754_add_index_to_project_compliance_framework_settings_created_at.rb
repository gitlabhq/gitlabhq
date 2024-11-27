# frozen_string_literal: true

class AddIndexToProjectComplianceFrameworkSettingsCreatedAt < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  disable_ddl_transaction!

  INDEX_CREATED_AT_TO_PROJECT_IDS = 'idx_on_project_id_created_at_for_compliance_framework_settings'

  def up
    add_concurrent_index :project_compliance_framework_settings, [:project_id, :created_at],
      name: INDEX_CREATED_AT_TO_PROJECT_IDS
  end

  def down
    remove_concurrent_index_by_name :project_compliance_framework_settings, INDEX_CREATED_AT_TO_PROJECT_IDS
  end
end
