# frozen_string_literal: true

class AddIndexToMrMetricsTargetProjectId < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_merge_request_metrics_on_target_project_id_merged_at'

  disable_ddl_transaction!

  def up
    add_concurrent_index :merge_request_metrics, [:target_project_id, :merged_at], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name(:merge_request_metrics, INDEX_NAME)
  end
end
