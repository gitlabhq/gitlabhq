# frozen_string_literal: true

class PrepareAsyncIndexOnMergeRequestCommitsMetadataId < Gitlab::Database::Migration[2.2]
  milestone '18.0'

  INDEX_NAME = 'index_mrdc_on_merge_request_commits_metadata_id'

  # TODO: Index to be created synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/527227
  # rubocop:disable Migration/PreventIndexCreation -- this index is required as
  # we will be querying data from `merge_request_commits_metadata_id` and joining
  # by this column.
  def up
    prepare_async_index :merge_request_diff_commits, :merge_request_commits_metadata_id, name: INDEX_NAME,
      where: "merge_request_commit_metadata_id IS NOT NULL"
  end
  # rubocop:enable Migration/PreventIndexCreation

  def down
    unprepare_async_index :merge_request_diff_commits, :merge_request_commits_metadata_id, name: INDEX_NAME
  end
end
