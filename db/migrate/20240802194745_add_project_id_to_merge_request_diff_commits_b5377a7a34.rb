# frozen_string_literal: true

class AddProjectIdToMergeRequestDiffCommitsB5377a7a34 < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  def up
    add_column :merge_request_diff_commits_b5377a7a34, :project_id, :bigint
  end

  def down
    remove_column :merge_request_diff_commits_b5377a7a34, :project_id
  end
end
