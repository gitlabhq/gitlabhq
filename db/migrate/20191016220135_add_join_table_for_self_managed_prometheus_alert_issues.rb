# frozen_string_literal: true

class AddJoinTableForSelfManagedPrometheusAlertIssues < ActiveRecord::Migration[5.2]
  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def change
    # Join table to Issues
    create_table :issues_self_managed_prometheus_alert_events, id: false do |t|
      t.references :issue, null: false,
        index: false, # Uses the index below
        foreign_key: { on_delete: :cascade }
      t.references :self_managed_prometheus_alert_event, null: false,
        index: { name: 'issue_id_issues_self_managed_rometheus_alert_events_index' },
        foreign_key: { on_delete: :cascade }

      t.timestamps_with_timezone
      t.index [:issue_id, :self_managed_prometheus_alert_event_id],
        unique: true, name: 'issue_id_self_managed_prometheus_alert_event_id_index'
    end
  end
end
