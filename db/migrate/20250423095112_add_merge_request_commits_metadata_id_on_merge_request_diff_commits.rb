# frozen_string_literal: true

class AddMergeRequestCommitsMetadataIdOnMergeRequestDiffCommits < Gitlab::Database::Migration[2.2]
  milestone '18.0'

  # rubocop:disable Migration/PreventAddingColumns -- this column is required as
  # we will be querying data from `merge_request_commits_metadata` table using
  # this column
  def change
    add_column :merge_request_diff_commits, :merge_request_commits_metadata_id, :bigint, null: true
  end
  # rubocop:enable Migration/PreventAddingColumns
end
