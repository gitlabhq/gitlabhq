class AllowManyPrometheusAlerts < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  # We mutate `:prometheus_metric_id` into non unique one,
  # and convert it into project+prometheus_metric unique
  def up
    rebuild_foreign_key do
      remove_concurrent_index :prometheus_alerts, :prometheus_metric_id, unique: true
      add_concurrent_index :prometheus_alerts, :prometheus_metric_id
      add_concurrent_index :prometheus_alerts, [:project_id, :prometheus_metric_id], unique: true
    end
  end

  def down
    rebuild_foreign_key do
      remove_concurrent_index :prometheus_alerts, [:project_id, :prometheus_metric_id], unique: true
      remove_concurrent_index :prometheus_alerts, :prometheus_metric_id
      add_concurrent_index :prometheus_alerts, :prometheus_metric_id, unique: true
    end
  end

  private

  # MySQL requires to drop FK for time of re-adding index
  def rebuild_foreign_key
    if Gitlab::Database.mysql?
      remove_foreign_key_without_error :prometheus_alerts, :prometheus_metrics
      remove_foreign_key_without_error :prometheus_alerts, :projects
    end

    yield

    if Gitlab::Database.mysql?
      add_concurrent_foreign_key :prometheus_alerts, :prometheus_metrics,
        column: :prometheus_metric_id, on_delete: :cascade
      add_concurrent_foreign_key :prometheus_alerts, :projects,
        column: :project_id, on_delete: :cascade
    end
  end
end
