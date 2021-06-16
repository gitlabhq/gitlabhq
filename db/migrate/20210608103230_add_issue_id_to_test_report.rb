# frozen_string_literal: true

class AddIssueIdToTestReport < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def up
    with_lock_retries do
      add_column :requirements_management_test_reports, :issue_id, :bigint, null: true
    end
  end

  def down
    with_lock_retries do
      remove_column :requirements_management_test_reports, :issue_id
    end
  end
end
