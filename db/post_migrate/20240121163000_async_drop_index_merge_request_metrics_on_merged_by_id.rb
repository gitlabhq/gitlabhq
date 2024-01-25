# frozen_string_literal: true

class AsyncDropIndexMergeRequestMetricsOnMergedById < Gitlab::Database::Migration[2.2]
  milestone '16.9'

  TABLE_NAME = 'merge_request_metrics'
  INDEX_NAME = 'index_merge_request_metrics_on_merged_by_id'
  COLUMN = 'merged_by_id'

  # TODO: Index to be destroyed synchronously in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142357
  def up
    prepare_async_index_removal TABLE_NAME, COLUMN, name: INDEX_NAME
  end

  def down
    unprepare_async_index TABLE_NAME, COLUMN, name: INDEX_NAME
  end
end
