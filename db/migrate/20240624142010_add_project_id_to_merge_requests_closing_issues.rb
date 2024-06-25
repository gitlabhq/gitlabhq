# frozen_string_literal: true

class AddProjectIdToMergeRequestsClosingIssues < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def change
    add_column :merge_requests_closing_issues, :project_id, :bigint
  end
end
