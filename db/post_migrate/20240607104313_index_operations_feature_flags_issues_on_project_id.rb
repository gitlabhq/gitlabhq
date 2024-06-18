# frozen_string_literal: true

class IndexOperationsFeatureFlagsIssuesOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  disable_ddl_transaction!

  INDEX_NAME = 'index_operations_feature_flags_issues_on_project_id'

  def up
    add_concurrent_index :operations_feature_flags_issues, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :operations_feature_flags_issues, INDEX_NAME
  end
end
