# frozen_string_literal: true

class IndexRequirementsManagementTestReportsOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  disable_ddl_transaction!

  INDEX_NAME = 'index_requirements_management_test_reports_on_project_id'

  def up
    add_concurrent_index :requirements_management_test_reports, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :requirements_management_test_reports, INDEX_NAME
  end
end
