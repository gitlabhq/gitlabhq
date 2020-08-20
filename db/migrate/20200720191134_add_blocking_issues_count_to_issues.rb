# frozen_string_literal: true

class AddBlockingIssuesCountToIssues < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_issue_on_project_id_state_id_and_blocking_issues_count'

  disable_ddl_transaction!

  def up
    unless column_exists?(:issues, :blocking_issues_count)
      with_lock_retries do
        add_column :issues, :blocking_issues_count, :integer, default: 0, null: false
      end
    end

    add_concurrent_index :issues, [:project_id, :state_id, :blocking_issues_count], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :issues, INDEX_NAME

    with_lock_retries do
      remove_column :issues, :blocking_issues_count
    end
  end
end
