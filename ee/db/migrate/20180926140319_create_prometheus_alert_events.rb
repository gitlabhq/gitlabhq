# frozen_string_literal: true

class CreatePrometheusAlertEvents < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  INDEX_ALERT_PAYLOAD_KEY = 'index_prometheus_alert_event_scoped_payload_key'

  def change
    create_table :prometheus_alert_events, id: :bigserial do |t|
      t.references :project, null: false, foreign_key: { on_delete: :cascade }
      t.references :prometheus_alert, null: false, foreign_key: { on_delete: :cascade }

      t.datetime_with_timezone :started_at, null: false
      t.datetime_with_timezone :ended_at
      t.integer :status, limit: 2
      t.string :payload_key

      t.index [:project_id, :status]
      t.index [:prometheus_alert_id, :payload_key], unique: true, name: INDEX_ALERT_PAYLOAD_KEY
    end
  end
end
