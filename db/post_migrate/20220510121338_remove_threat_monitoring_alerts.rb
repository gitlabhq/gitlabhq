# frozen_string_literal: true

class RemoveThreatMonitoringAlerts < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    execute("DELETE FROM alert_management_alerts WHERE domain = 1")
  end

  def down
    # no-op
  end
end
