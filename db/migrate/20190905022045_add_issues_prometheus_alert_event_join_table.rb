# frozen_string_literal: true

class AddIssuesPrometheusAlertEventJoinTable < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :issues_prometheus_alert_events, id: false do |t|
      t.references :issue, null: false,
        index: false, # Uses the index below
        foreign_key: { on_delete: :cascade }
      t.references :prometheus_alert_event, null: false,
        index: { name: 'issue_id_issues_prometheus_alert_events_index' },
        foreign_key: { on_delete: :cascade }

      t.timestamps_with_timezone
      t.index [:issue_id, :prometheus_alert_event_id],
        unique: true, name: 'issue_id_prometheus_alert_event_id_index'
    end
  end
end
