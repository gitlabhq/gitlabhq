# frozen_string_literal: true

class AddClosesWorkItemToMergeRequestsMergeRequestsClosingIssues < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  def change
    add_column :merge_requests_closing_issues, :closes_work_item, :boolean, default: true, null: false
  end
end
