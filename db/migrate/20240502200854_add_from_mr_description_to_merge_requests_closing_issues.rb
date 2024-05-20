# frozen_string_literal: true

class AddFromMrDescriptionToMergeRequestsClosingIssues < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :merge_requests_closing_issues, :from_mr_description, :boolean, default: true, null: false
  end
end
