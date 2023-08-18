# frozen_string_literal: true

class RemoveIssuesIssueTypeColumn < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    remove_column :issues, :issue_type
  end

  def down
    add_column :issues, :issue_type, :smallint, default: 0, null: false
  end
end
