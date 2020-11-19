# frozen_string_literal: true

class ChangeIndexMrMetricsTargetProjectId < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  DOWNTIME = false
  INDEX_NAME = 'index_merge_request_metrics_on_target_project_id_merged_at'
  NULLS_LAST_INDEX_NAME = 'index_mr_metrics_on_target_project_id_merged_at_nulls_last'

  def up
    add_concurrent_index :merge_request_metrics, [:target_project_id, :merged_at, :id], order: { merged_at: 'DESC NULLS LAST', id: 'DESC' }, name: NULLS_LAST_INDEX_NAME
    remove_concurrent_index_by_name(:merge_request_metrics, INDEX_NAME)
  end

  def down
    add_concurrent_index :merge_request_metrics, [:target_project_id, :merged_at], name: INDEX_NAME
    remove_concurrent_index_by_name(:merge_request_metrics, NULLS_LAST_INDEX_NAME)
  end
end
