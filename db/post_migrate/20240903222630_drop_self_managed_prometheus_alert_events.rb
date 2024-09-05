# frozen_string_literal: true

class DropSelfManagedPrometheusAlertEvents < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  TABLE_NAME = :self_managed_prometheus_alert_events
  UNIQUE_INDEX_NAME = :idx_project_id_payload_key_self_managed_prometheus_alert_events
  ENVIRONMENT_INDEX = :index_self_managed_prometheus_alert_events_on_environment_id

  def up
    drop_table TABLE_NAME
  end

  # Original SQL:
  #
  # CREATE TABLE self_managed_prometheus_alert_events (
  #   id bigint NOT NULL,
  #   project_id bigint NOT NULL,
  #   environment_id bigint,
  #   started_at timestamp with time zone NOT NULL,
  #   ended_at timestamp with time zone,
  #   status smallint NOT NULL,
  #   title character varying(255) NOT NULL,
  #   query_expression character varying(255),
  #   payload_key character varying(255) NOT NULL
  # );
  #
  # CREATE SEQUENCE self_managed_prometheus_alert_events_id_seq
  #     START WITH 1
  #     INCREMENT BY 1
  #     NO MINVALUE
  #     NO MAXVALUE
  #     CACHE 1;
  #
  # ALTER SEQUENCE self_managed_prometheus_alert_events_id_seq OWNED BY self_managed_prometheus_alert_events.id;
  #
  # CREATE UNIQUE INDEX idx_project_id_payload_key_self_managed_prometheus_alert_events
  #     ON self_managed_prometheus_alert_events USING btree (project_id, payload_key);
  #
  # CREATE INDEX index_self_managed_prometheus_alert_events_on_environment_id ON self_managed_prometheus_alert_events
  #     USING btree (environment_id);
  #
  def down
    create_table TABLE_NAME do |t|
      t.bigint :project_id, null: false
      t.bigint :environment_id
      t.datetime_with_timezone :started_at, null: false
      t.datetime_with_timezone :ended_at
      t.integer :status, limit: 2, null: false
      t.string :title, limit: 255, null: false
      t.string :query_expression, limit: 255
      t.string :payload_key, limit: 255, null: false

      t.index [:project_id, :payload_key], name: UNIQUE_INDEX_NAME, unique: true
      t.index :environment_id, name: ENVIRONMENT_INDEX
    end
  end
end
