# frozen_string_literal: true

class CreateAlertManagementAlerts < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless table_exists?(:alert_management_alerts)
      create_table :alert_management_alerts do |t|
        t.timestamps_with_timezone
        t.datetime_with_timezone :started_at, null: false
        t.datetime_with_timezone :ended_at
        t.integer :events, default: 1, null: false
        t.integer :iid, null: false
        t.integer :severity, default: 0, null: false, limit: 2
        t.integer :status, default: 0, null: false, limit: 2
        t.binary :fingerprint
        t.bigint :issue_id, index: true
        t.bigint :project_id, null: false
        t.text :title, null: false
        t.text :description
        t.text :service
        t.text :monitoring_tool
        t.text :hosts, array: true, null: false, default: [] # rubocop:disable Migration/AddLimitToTextColumns
        t.jsonb :payload, null: false, default: {}

        t.index %w(project_id iid), name: 'index_alert_management_alerts_on_project_id_and_iid', unique: true, using: :btree
        t.index %w(project_id fingerprint), name: 'index_alert_management_alerts_on_project_id_and_fingerprint', unique: true, using: :btree
      end
    end

    add_text_limit :alert_management_alerts, :title, 200
    add_text_limit :alert_management_alerts, :description, 1000
    add_text_limit :alert_management_alerts, :service, 100
    add_text_limit :alert_management_alerts, :monitoring_tool, 100
  end

  def down
    drop_table :alert_management_alerts
  end
end
