# frozen_string_literal: true

class AddOptionalMetricsEnabledToApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone '16.9'

  def up
    add_column :application_settings, :include_optional_metrics_in_service_ping, :boolean, default: true, null: false
  end

  def down
    remove_column :application_settings, :include_optional_metrics_in_service_ping
  end
end
