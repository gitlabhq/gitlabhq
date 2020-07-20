# frozen_string_literal: true

class AddPrometheusAlertIdToAlertManagementAlerts < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    add_column :alert_management_alerts, :prometheus_alert_id, :integer

    add_column :alert_management_alerts, :environment_id, :integer
  end

  def down
    remove_column :alert_management_alerts, :prometheus_alert_id
    remove_column :alert_management_alerts, :environment_id
  end
end
