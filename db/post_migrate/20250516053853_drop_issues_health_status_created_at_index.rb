# frozen_string_literal: true

class DropIssuesHealthStatusCreatedAtIndex < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  disable_ddl_transaction!

  INDEX_NAME = 'index_issues_on_project_id_health_status_created_at_id'
  COLUMNS = %i[project_id health_status created_at id]

  def up
    remove_concurrent_index_by_name :issues, name: INDEX_NAME
  end

  def down
    add_concurrent_index :issues, COLUMNS, name: INDEX_NAME
  end
end
