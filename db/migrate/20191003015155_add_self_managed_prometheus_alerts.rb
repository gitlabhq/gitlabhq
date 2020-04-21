# frozen_string_literal: true

class AddSelfManagedPrometheusAlerts < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    create_table :self_managed_prometheus_alert_events do |t|
      t.references :project, index: false, foreign_key: { on_delete: :cascade }, null: false
      t.references :environment, index: true, foreign_key: { on_delete: :cascade }
      t.datetime_with_timezone :started_at, null: false
      t.datetime_with_timezone :ended_at

      t.integer :status, null: false, limit: 2
      t.string :title, null: false, limit: 255
      t.string :query_expression, limit: 255
      t.string :payload_key, null: false, limit: 255
      t.index [:project_id, :payload_key], unique: true, name: 'idx_project_id_payload_key_self_managed_prometheus_alert_events'
    end
  end
  # rubocop:enable Migration/PreventStrings
end
