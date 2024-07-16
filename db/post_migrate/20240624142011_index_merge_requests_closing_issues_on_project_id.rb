# frozen_string_literal: true

class IndexMergeRequestsClosingIssuesOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.2'
  disable_ddl_transaction!

  INDEX_NAME = 'index_merge_requests_closing_issues_on_project_id'

  def up
    add_concurrent_index :merge_requests_closing_issues, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :merge_requests_closing_issues, INDEX_NAME
  end
end
