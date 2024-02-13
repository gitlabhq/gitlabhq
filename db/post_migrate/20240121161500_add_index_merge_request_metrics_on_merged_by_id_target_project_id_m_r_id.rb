# frozen_string_literal: true

class AddIndexMergeRequestMetricsOnMergedByIdTargetProjectIdMRId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.9'

  TABLE_NAME = :merge_request_metrics
  INDEX_NAME = :idx_merge_request_metrics_on_merged_by_project_and_mr
  INDEX_COLUMNS = %i[merged_by_id target_project_id merge_request_id]

  DROP_INDEX_NAME = :index_merge_request_metrics_on_merged_by_id
  DROP_INDEX_COLUMNS = %i[merged_by_id]

  def up
    add_concurrent_index TABLE_NAME, INDEX_COLUMNS, name: INDEX_NAME
    # the existing index index_merge_request_metrics_on_merged_by_id is now redundant and should be removed
    remove_concurrent_index TABLE_NAME, DROP_INDEX_COLUMNS, name: DROP_INDEX_NAME
  end

  def down
    # recreate the existing index index_merge_request_metrics_on_merged_by_id
    add_concurrent_index TABLE_NAME, DROP_INDEX_COLUMNS, name: DROP_INDEX_NAME
    remove_concurrent_index TABLE_NAME, INDEX_COLUMNS, name: INDEX_NAME
  end
end
