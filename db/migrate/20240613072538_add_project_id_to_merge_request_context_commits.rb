# frozen_string_literal: true

class AddProjectIdToMergeRequestContextCommits < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :merge_request_context_commits, :project_id, :bigint
  end
end
