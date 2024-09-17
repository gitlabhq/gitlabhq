# frozen_string_literal: true

class DropPrometheusAlerts < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  TABLE_NAME = :prometheus_alerts
  UNIQUE_INDEX_NAME = :index_prometheus_alerts_metric_environment
  ENVIRONMENT_INDEX_NAME = :index_prometheus_alerts_on_environment_id
  METRIC_INDEX_NAME = :index_prometheus_alerts_on_prometheus_metric_id

  def up
    drop_table TABLE_NAME
  end

  # Original SQL:
  #
  # CREATE TABLE prometheus_alerts (
  #   id bigint NOT NULL,
  #   created_at timestamp with time zone NOT NULL,
  #   updated_at timestamp with time zone NOT NULL,
  #   threshold double precision NOT NULL,
  #   operator integer NOT NULL,
  #   environment_id bigint NOT NULL,
  #   project_id bigint NOT NULL,
  #   prometheus_metric_id bigint NOT NULL,
  #   runbook_url text,
  #   CONSTRAINT check_cb76d7e629 CHECK ((char_length(runbook_url) <= 255))
  # );
  #
  # CREATE SEQUENCE prometheus_alerts_id_seq
  #     START WITH 1
  #     INCREMENT BY 1
  #     NO MINVALUE
  #     NO MAXVALUE
  #     CACHE 1;
  #
  # ALTER SEQUENCE prometheus_alerts_id_seq OWNED BY prometheus_alerts.id;
  #
  # CREATE UNIQUE INDEX index_prometheus_alerts_metric_environment ON prometheus_alerts
  #     USING btree (project_id, prometheus_metric_id, environment_id);
  #
  # CREATE INDEX index_prometheus_alerts_on_environment_id ON prometheus_alerts USING btree (environment_id);
  #
  # CREATE INDEX index_prometheus_alerts_on_prometheus_metric_id ON prometheus_alerts
  #     USING btree (prometheus_metric_id);
  #
  def down
    create_table TABLE_NAME do |t|
      t.timestamps_with_timezone null: false
      t.float :threshold, null: false
      t.integer :operator, null: false
      t.bigint :environment_id, null: false
      t.bigint :project_id, null: false
      t.bigint :prometheus_metric_id, null: false
      t.text :runbook_url, limit: 255

      t.index [:project_id, :prometheus_metric_id, :environment_id], name: UNIQUE_INDEX_NAME, unique: true
      t.index :environment_id, name: ENVIRONMENT_INDEX_NAME
      t.index :prometheus_metric_id, name: METRIC_INDEX_NAME
    end
  end
end
