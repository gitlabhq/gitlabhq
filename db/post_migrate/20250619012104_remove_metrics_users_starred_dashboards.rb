# frozen_string_literal: true

class RemoveMetricsUsersStarredDashboards < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  def up
    drop_table :metrics_users_starred_dashboards
  end

  def down
    execute <<~SQL
      CREATE TABLE metrics_users_starred_dashboards (
        id bigint NOT NULL,
        created_at timestamp with time zone NOT NULL,
        updated_at timestamp with time zone NOT NULL,
        project_id bigint NOT NULL,
        user_id bigint NOT NULL,
        dashboard_path text NOT NULL,
        CONSTRAINT check_79a84a0f57 CHECK ((char_length(dashboard_path) <= 255))
      );

      CREATE SEQUENCE metrics_users_starred_dashboards_id_seq
        START WITH 1
        INCREMENT BY 1
        NO MINVALUE
        NO MAXVALUE
        CACHE 1;

      ALTER SEQUENCE metrics_users_starred_dashboards_id_seq OWNED BY metrics_users_starred_dashboards.id;

      ALTER TABLE ONLY metrics_users_starred_dashboards
        ALTER COLUMN id SET DEFAULT nextval('metrics_users_starred_dashboards_id_seq'::regclass);

      ALTER TABLE ONLY metrics_users_starred_dashboards
        ADD CONSTRAINT metrics_users_starred_dashboards_pkey PRIMARY KEY (id);

      CREATE UNIQUE INDEX idx_metrics_users_starred_dashboard_on_user_project_dashboard
        ON metrics_users_starred_dashboards USING btree (user_id, project_id, dashboard_path);

      CREATE INDEX index_metrics_users_starred_dashboards_on_project_id
        ON metrics_users_starred_dashboards USING btree (project_id);

      ALTER TABLE ONLY metrics_users_starred_dashboards
        ADD CONSTRAINT fk_bd6ae32fac FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

      ALTER TABLE ONLY metrics_users_starred_dashboards
        ADD CONSTRAINT fk_d76a2b9a8c FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE;
    SQL
  end
end
