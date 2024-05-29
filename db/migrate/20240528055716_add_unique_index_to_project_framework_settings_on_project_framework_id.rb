# frozen_string_literal: true

class AddUniqueIndexToProjectFrameworkSettingsOnProjectFrameworkId < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  disable_ddl_transaction!

  EXISTING_INDEX_NAME = 'index_project_compliance_framework_settings_on_project_id'
  NEW_INDEX_NAME = 'uniq_idx_project_compliance_framework_on_project_framework'
  COLUMNS = %i[project_id framework_id]

  def up
    remove_concurrent_index_by_name :project_compliance_framework_settings, EXISTING_INDEX_NAME

    add_concurrent_index :project_compliance_framework_settings, COLUMNS, unique: true, name: NEW_INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :project_compliance_framework_settings, NEW_INDEX_NAME

    add_concurrent_index :project_compliance_framework_settings, :project_id, name: EXISTING_INDEX_NAME
  end
end
