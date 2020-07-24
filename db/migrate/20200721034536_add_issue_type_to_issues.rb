# frozen_string_literal: true

class AddIssueTypeToIssues < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      # Set default to issue type
      add_column :issues, :issue_type, :integer, limit: 2, default: 0, null: false
    end
  end

  def down
    with_lock_retries do
      remove_column :issues, :issue_type
    end
  end
end
