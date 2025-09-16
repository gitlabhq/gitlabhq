# frozen_string_literal: true

class RemoveAlertsPrometheusAlertIdColumn < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  disable_ddl_transaction!

  TABLE_NAME = 'alert_management_alerts'
  COLUMN_NAME = 'prometheus_alert_id'
  INDEX_NAME = 'index_alert_management_alerts_on_prometheus_alert_id'

  def up
    with_lock_retries do
      remove_column TABLE_NAME, COLUMN_NAME, if_exists: true
    end
  end

  def down
    with_lock_retries do
      add_column TABLE_NAME, COLUMN_NAME, :bigint, if_not_exists: true
    end

    add_concurrent_index TABLE_NAME, COLUMN_NAME, name: INDEX_NAME, where: 'prometheus_alert_id IS NOT NULL'
  end
end
