# frozen_string_literal: true

class DropIssuesPrometheusAlertEvents < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  TABLE_NAME = :issues_prometheus_alert_events
  PRIMARY_KEY = :issues_prometheus_alert_events_pkey
  INDEX_NAME = :issue_id_issues_prometheus_alert_events_index

  def up
    drop_table TABLE_NAME
  end

  # Original SQL:
  #
  # CREATE TABLE issues_prometheus_alert_events (
  #   issue_id bigint NOT NULL,
  #   prometheus_alert_event_id bigint NOT NULL,
  #   created_at timestamp with time zone NOT NULL,
  #   updated_at timestamp with time zone NOT NULL
  # );
  #
  # CREATE INDEX issue_id_issues_prometheus_alert_events_index ON issues_prometheus_alert_events
  #     USING btree (prometheus_alert_event_id);
  #
  # ALTER TABLE ONLY issues_prometheus_alert_events
  #     ADD CONSTRAINT issues_prometheus_alert_events_pkey PRIMARY KEY (issue_id, prometheus_alert_event_id);
  #
  def down
    create_table TABLE_NAME, primary_key: [:issue_id, :prometheus_alert_event_id] do |t|
      t.bigint :issue_id, null: false
      t.bigint :prometheus_alert_event_id, null: false
      t.timestamps_with_timezone null: false

      t.index :prometheus_alert_event_id, name: INDEX_NAME
    end
  end
end
