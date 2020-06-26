# frozen_string_literal: true

class AddIdxAndFkForPrometheusAndEnvironmentToAlertManagementAlerts < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :alert_management_alerts, :prometheus_alert_id, where: 'prometheus_alert_id is not null'
    add_concurrent_foreign_key :alert_management_alerts, :prometheus_alerts, column: :prometheus_alert_id, on_delete: :cascade

    add_concurrent_index :alert_management_alerts, :environment_id, where: 'environment_id is not null'
    add_concurrent_foreign_key :alert_management_alerts, :environments, column: :environment_id, on_delete: :nullify
  end

  def down
    remove_concurrent_index :alert_management_alerts, :prometheus_alert_id
    remove_foreign_key_without_error :alert_management_alerts, column: :prometheus_alert_id

    remove_concurrent_index :alert_management_alerts, :environment_id
    remove_foreign_key_without_error :alert_management_alerts, column: :environment_id
  end
end
