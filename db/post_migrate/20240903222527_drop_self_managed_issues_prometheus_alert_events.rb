# frozen_string_literal: true

class DropSelfManagedIssuesPrometheusAlertEvents < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  TABLE_NAME = :issues_self_managed_prometheus_alert_events
  PRIMARY_KEY = :issues_self_managed_prometheus_alert_events_pkey
  INDEX_NAME = :issue_id_issues_self_managed_rometheus_alert_events_index

  def up
    drop_table TABLE_NAME
  end

  # Original SQL:
  #
  # CREATE TABLE issues_self_managed_prometheus_alert_events (
  #   issue_id bigint NOT NULL,
  #   self_managed_prometheus_alert_event_id bigint NOT NULL,
  #   created_at timestamp with time zone NOT NULL,
  #   updated_at timestamp with time zone NOT NULL
  # );
  #
  # CREATE INDEX issue_id_issues_self_managed_rometheus_alert_events_index
  #     ON issues_self_managed_prometheus_alert_events USING btree (self_managed_prometheus_alert_event_id);
  #
  # ALTER TABLE ONLY issues_self_managed_prometheus_alert_events
  #     ADD CONSTRAINT issues_self_managed_prometheus_alert_events_pkey
  #     PRIMARY KEY (issue_id, self_managed_prometheus_alert_event_id);
  #
  def down
    create_table TABLE_NAME, primary_key: [:issue_id, :self_managed_prometheus_alert_event_id] do |t|
      t.bigint :issue_id, null: false
      t.bigint :self_managed_prometheus_alert_event_id, null: false
      t.timestamps_with_timezone null: false

      t.index :self_managed_prometheus_alert_event_id, name: INDEX_NAME
    end
  end
end
