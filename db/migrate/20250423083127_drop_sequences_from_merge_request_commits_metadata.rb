# frozen_string_literal: true

class DropSequencesFromMergeRequestCommitsMetadata < Gitlab::Database::Migration[2.2]
  milestone '18.0'

  def up
    drop_sequence(
      :merge_request_commits_metadata,
      :project_id,
      :merge_request_commits_metadata_project_id_seq
    )

    drop_sequence(
      :merge_request_commits_metadata,
      :commit_author_id,
      :merge_request_commits_metadata_commit_author_id_seq
    )

    drop_sequence(
      :merge_request_commits_metadata,
      :committer_id,
      :merge_request_commits_metadata_committer_id_seq
    )
  end

  def down
    # no-op since we don't really want sequences for these columns.
  end
end
