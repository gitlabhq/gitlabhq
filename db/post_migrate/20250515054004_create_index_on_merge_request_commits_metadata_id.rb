# frozen_string_literal: true

class CreateIndexOnMergeRequestCommitsMetadataId < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  INDEX_NAME = 'index_mrdc_on_merge_request_commits_metadata_id'

  disable_ddl_transaction!

  # rubocop:disable Migration/PreventIndexCreation -- this index is already
  # present on GitLab.com which was prepared in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/189775.
  def up
    add_concurrent_index(
      :merge_request_diff_commits,
      :merge_request_commits_metadata_id,
      name: INDEX_NAME,
      where: "merge_request_commits_metadata_id IS NOT NULL"
    )
  end
  # rubocop:enable Migration/PreventIndexCreation

  def down
    remove_concurrent_index_by_name :merge_request_diff_commits, INDEX_NAME
  end
end
