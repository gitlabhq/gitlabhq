# frozen_string_literal: true

class PrepareAsyncIndexesForMergeRequestDiffFiles99208b8fac < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '19.0'

  TABLE_NAME = :merge_request_diff_files_99208b8fac
  PROJECT_ID_INDEX_NAME = 'index_merge_request_diff_files_99208b8fac_on_project_id'
  MR_DIFF_ID_INDEX_NAME = 'index_merge_request_diff_files_99208b8fac_on_mr_diff_id'

  def up
    prepare_partitioned_async_index TABLE_NAME, :project_id, name: PROJECT_ID_INDEX_NAME
    prepare_partitioned_async_index TABLE_NAME, :merge_request_diff_id, name: MR_DIFF_ID_INDEX_NAME
  end

  def down
    unprepare_partitioned_async_index TABLE_NAME, :project_id, name: PROJECT_ID_INDEX_NAME
    unprepare_partitioned_async_index TABLE_NAME, :merge_request_diff_id, name: MR_DIFF_ID_INDEX_NAME
  end
end
