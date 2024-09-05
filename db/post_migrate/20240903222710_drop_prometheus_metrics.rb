# frozen_string_literal: true

class DropPrometheusMetrics < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  TABLE_NAME = :prometheus_metrics
  UNIQUE_NULL_PROJECT_INDEX = :index_prometheus_metrics_on_identifier_and_null_project
  UNIQUE_PROJECT_INDEX = :index_prometheus_metrics_on_identifier_and_project_id
  COMMON_INDEX = :index_prometheus_metrics_on_common
  GROUP_INDEX = :index_prometheus_metrics_on_group
  PROJECT_INDEX = :index_prometheus_metrics_on_project_id

  def up
    drop_table TABLE_NAME
  end

  # Original SQL:
  #
  # CREATE TABLE prometheus_metrics (
  #   id bigint NOT NULL,
  #   project_id bigint,
  #   title character varying NOT NULL,
  #   query character varying NOT NULL,
  #   y_label character varying NOT NULL,
  #   unit character varying NOT NULL,
  #   legend character varying,
  #   "group" integer NOT NULL,
  #   created_at timestamp with time zone NOT NULL,
  #   updated_at timestamp with time zone NOT NULL,
  #   common boolean DEFAULT false NOT NULL,
  #   identifier character varying,
  #   dashboard_path text,
  #   CONSTRAINT check_0ad9f01463 CHECK ((char_length(dashboard_path) <= 2048))
  # );
  # CREATE SEQUENCE prometheus_metrics_id_seq
  #     START WITH 1
  #     INCREMENT BY 1
  #     NO MINVALUE
  #     NO MAXVALUE
  #     CACHE 1;
  #
  # ALTER SEQUENCE prometheus_metrics_id_seq OWNED BY prometheus_metrics.id;
  #
  # CREATE INDEX index_prometheus_metrics_on_common ON prometheus_metrics USING btree (common);
  #
  # CREATE INDEX index_prometheus_metrics_on_group ON prometheus_metrics USING btree ("group");
  #
  # CREATE UNIQUE INDEX index_prometheus_metrics_on_identifier_and_null_project ON prometheus_metrics
  #     USING btree (identifier) WHERE (project_id IS NULL);
  #
  # CREATE UNIQUE INDEX index_prometheus_metrics_on_identifier_and_project_id ON prometheus_metrics
  #     USING btree (identifier, project_id);
  #
  # CREATE INDEX index_prometheus_metrics_on_project_id ON prometheus_metrics USING btree (project_id);
  #
  def down
    create_table TABLE_NAME do |t|
      t.bigint :project_id
      t.string :title, null: false
      t.string :query, null: false
      t.string :y_label, null: false
      t.string :unit, null: false
      t.string :legend
      t.integer "group", null: false
      t.timestamps_with_timezone null: false
      t.boolean :common, null: false, default: false
      t.string :identifier
      t.text :dashboard_path, limit: 2048

      t.index :common, name: COMMON_INDEX
      t.index "group", name: GROUP_INDEX
      t.index :identifier, unique: true, name: UNIQUE_NULL_PROJECT_INDEX, where: 'project_id IS NULL'
      t.index [:identifier, :project_id], unique: true, name: UNIQUE_PROJECT_INDEX
      t.index :project_id, name: PROJECT_INDEX
    end
  end
end
