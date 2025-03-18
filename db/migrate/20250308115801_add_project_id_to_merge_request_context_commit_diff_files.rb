# frozen_string_literal: true

class AddProjectIdToMergeRequestContextCommitDiffFiles < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    add_column :merge_request_context_commit_diff_files, :project_id, :bigint
  end
end
