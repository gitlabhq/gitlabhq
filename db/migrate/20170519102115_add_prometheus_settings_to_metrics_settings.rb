class AddPrometheusSettingsToMetricsSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false

  def up
    add_column_with_default(:application_settings, :prometheus_metrics_enabled, :boolean,
                            default: false, allow_null: false)
  end

  def down
    remove_column(:application_settings, :prometheus_metrics_enabled)
  end
end
