# frozen_string_literal: true

class RemoveRedundantMrMetricsIndexOnTargetProjectId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.6'

  INDEX_NAME = 'index_merge_request_metrics_on_target_project_id'

  def up
    remove_concurrent_index_by_name(:merge_request_metrics, INDEX_NAME)
  end

  def down
    add_concurrent_index(:merge_request_metrics, :target_project_id, name: INDEX_NAME)
  end
end
