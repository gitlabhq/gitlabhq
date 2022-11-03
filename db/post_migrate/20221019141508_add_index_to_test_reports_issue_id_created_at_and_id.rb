# frozen_string_literal: true

class AddIndexToTestReportsIssueIdCreatedAtAndId < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  TABLE_NAME = 'requirements_management_test_reports'
  INDEX_NAME = 'idx_test_reports_on_issue_id_created_at_and_id'

  def up
    add_concurrent_index TABLE_NAME, [:issue_id, :created_at, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end
