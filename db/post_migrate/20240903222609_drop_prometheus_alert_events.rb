# frozen_string_literal: true

class DropPrometheusAlertEvents < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  TABLE_NAME = :prometheus_alert_events
  UNIQUE_INDEX_NAME = :index_prometheus_alert_event_scoped_payload_key
  STATUS_INDEX = :index_prometheus_alert_events_on_project_id_and_status

  def up
    drop_table TABLE_NAME
  end

  # Original SQL:
  #
  # CREATE TABLE prometheus_alert_events (
  #   id bigint NOT NULL,
  #   project_id bigint NOT NULL,
  #   prometheus_alert_id bigint NOT NULL,
  #   started_at timestamp with time zone NOT NULL,
  #   ended_at timestamp with time zone,
  #   status smallint,
  #   payload_key character varying
  # );
  #
  # CREATE SEQUENCE prometheus_alert_events_id_seq
  #     START WITH 1
  #     INCREMENT BY 1
  #     NO MINVALUE
  #     NO MAXVALUE
  #     CACHE 1;
  #
  # ALTER SEQUENCE prometheus_alert_events_id_seq OWNED BY prometheus_alert_events.id;
  #
  # CREATE UNIQUE INDEX index_prometheus_alert_event_scoped_payload_key ON prometheus_alert_events
  #     USING btree (prometheus_alert_id, payload_key);
  #
  # CREATE INDEX index_prometheus_alert_events_on_project_id_and_status ON prometheus_alert_events
  #     USING btree (project_id, status);
  #
  def down
    create_table TABLE_NAME do |t|
      t.bigint :project_id, null: false
      t.bigint :prometheus_alert_id, null: false
      t.datetime_with_timezone :started_at, null: false
      t.datetime_with_timezone :ended_at
      t.integer :status, limit: 2
      t.string :payload_key

      t.index [:prometheus_alert_id, :payload_key], name: UNIQUE_INDEX_NAME, unique: true
      t.index [:project_id, :status], name: STATUS_INDEX
    end
  end
end
