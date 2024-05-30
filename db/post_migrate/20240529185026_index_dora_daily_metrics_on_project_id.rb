# frozen_string_literal: true

class IndexDoraDailyMetricsOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  disable_ddl_transaction!

  INDEX_NAME = 'index_dora_daily_metrics_on_project_id'

  def up
    add_concurrent_index :dora_daily_metrics, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :dora_daily_metrics, INDEX_NAME
  end
end
