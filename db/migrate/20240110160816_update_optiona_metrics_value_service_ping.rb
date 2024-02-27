# frozen_string_literal: true

class UpdateOptionaMetricsValueServicePing < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '16.9'

  def up
    execute <<~SQL
      UPDATE application_settings
      SET include_optional_metrics_in_service_ping = usage_ping_enabled
    SQL
  end

  def down
    # No-op
  end
end
