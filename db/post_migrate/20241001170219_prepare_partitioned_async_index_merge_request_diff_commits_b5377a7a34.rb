# frozen_string_literal: true

class PreparePartitionedAsyncIndexMergeRequestDiffCommitsB5377a7a34 < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '17.5'
  disable_ddl_transaction!

  INDEX_NAME = 'index_merge_request_diff_commits_b5377a7a34_on_project_id'

  def up
    prepare_partitioned_async_index :merge_request_diff_commits_b5377a7a34, :project_id, name: INDEX_NAME
  end

  def down
    unprepare_partitioned_async_index_by_name :merge_request_diff_commits_b5377a7a34, INDEX_NAME
  end
end
