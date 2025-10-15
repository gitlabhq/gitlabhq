# frozen_string_literal: true

class UpdateLatestClosedByIndexMergeRequestMetrics < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.5'

  OLD_INDEX_NAME = 'index_merge_request_metrics_on_latest_closed_at'
  NEW_INDEX_NAME = 'idx_mr_metrics_on_project_closed_at_with_mr_id'

  def up
    remove_concurrent_index_by_name :merge_request_metrics, OLD_INDEX_NAME

    # rubocop:disable Migration/PreventIndexCreation -- Replacing existing index
    add_concurrent_index :merge_request_metrics, [:target_project_id, :latest_closed_at, :merge_request_id],
      where: 'latest_closed_at IS NOT null', name: NEW_INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation -- Replacing existing index
  end

  def down
    remove_concurrent_index_by_name :merge_request_metrics, NEW_INDEX_NAME

    add_concurrent_index :merge_request_metrics, [:latest_closed_at],
      where: 'latest_closed_at IS NOT null', name: OLD_INDEX_NAME
  end
end
