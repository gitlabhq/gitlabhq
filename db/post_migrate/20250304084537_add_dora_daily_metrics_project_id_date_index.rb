# frozen_string_literal: true

class AddDoraDailyMetricsProjectIdDateIndex < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.10'

  INDEX_NAME = 'index_dora_daily_metrics_on_project_id_and_date'
  OLD_INDEX_NAME = 'index_dora_daily_metrics_on_project_id'

  def up
    add_concurrent_index(:dora_daily_metrics, [:project_id, :date], name: INDEX_NAME)
    remove_concurrent_index_by_name(:dora_daily_metrics, OLD_INDEX_NAME)
  end

  def down
    add_concurrent_index(:dora_daily_metrics, :project_id, name: OLD_INDEX_NAME)
    remove_concurrent_index_by_name(:dora_daily_metrics, INDEX_NAME)
  end
end
