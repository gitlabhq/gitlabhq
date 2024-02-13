# frozen_string_literal: true

class AddAsyncIndexMergeRequestMetricsOnMergedByIdTargetProjectIdMRId < Gitlab::Database::Migration[2.2]
  milestone '16.9'

  TABLE_NAME = :merge_request_metrics
  INDEX_NAME = :idx_merge_request_metrics_on_merged_by_project_and_mr
  INDEX_COLUMNS = %i[merged_by_id target_project_id merge_request_id]

  def up
    prepare_async_index TABLE_NAME, INDEX_COLUMNS, name: INDEX_NAME
  end

  def down
    unprepare_async_index TABLE_NAME, INDEX_COLUMNS, name: INDEX_NAME
  end
end
