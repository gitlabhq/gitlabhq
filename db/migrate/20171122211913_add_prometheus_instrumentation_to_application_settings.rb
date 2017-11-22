class AddPrometheusInstrumentationToApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  disable_ddl_transaction!

  def up
    add_column_with_default(:application_settings, :prometheus_metrics_method_instrumentation_enabled, :boolean,
                            default: false, allow_null: false)
  end

  def down
    remove_column(:application_settings, :prometheus_metrics_method_instrumentation_enabled)
  end
end

