# frozen_string_literal: true

class RemoveMergeRequestsClosingIssuesClosesWorkItemColumn < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def up
    remove_column :merge_requests_closing_issues, :closes_work_item
  end

  def down
    add_column :merge_requests_closing_issues, :closes_work_item, :boolean, default: true, null: false
  end
end
