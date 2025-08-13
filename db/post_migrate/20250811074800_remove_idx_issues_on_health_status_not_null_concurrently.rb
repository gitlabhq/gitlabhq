# frozen_string_literal: true

class RemoveIdxIssuesOnHealthStatusNotNullConcurrently < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  INDEX_NAME = 'idx_issues_on_health_status_not_null'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :issues, name: INDEX_NAME
  end

  def down
    add_concurrent_index :issues, [:health_status], where: "health_status IS NOT NULL", name: INDEX_NAME
  end
end
