# frozen_string_literal: true

class AddIssueIndexToTestReport < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  INDEX_NAME = 'index_requirements_management_test_reports_on_issue_id'

  def up
    add_concurrent_index :requirements_management_test_reports, :issue_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :requirements_management_test_reports, INDEX_NAME
  end
end
