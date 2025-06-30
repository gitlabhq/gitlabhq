# frozen_string_literal: true

class RemoveMetricsDashboardAnnotations < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  def up
    drop_table :metrics_dashboard_annotations
  end

  def down
    execute <<~SQL
      CREATE TABLE metrics_dashboard_annotations (
        id bigint NOT NULL,
        starting_at timestamp with time zone NOT NULL,
        ending_at timestamp with time zone,
        environment_id bigint,
        cluster_id bigint,
        dashboard_path character varying(255) NOT NULL,
        panel_xid character varying(255),
        description text NOT NULL
      );

      CREATE SEQUENCE metrics_dashboard_annotations_id_seq
        START WITH 1
        INCREMENT BY 1
        NO MINVALUE
        NO MAXVALUE
        CACHE 1;

      ALTER SEQUENCE metrics_dashboard_annotations_id_seq OWNED BY metrics_dashboard_annotations.id;

      ALTER TABLE ONLY metrics_dashboard_annotations
        ALTER COLUMN id SET DEFAULT nextval('metrics_dashboard_annotations_id_seq'::regclass);

      ALTER TABLE ONLY metrics_dashboard_annotations
        ADD CONSTRAINT metrics_dashboard_annotations_pkey PRIMARY KEY (id);

      CREATE INDEX index_metrics_dashboard_annotations_on_cluster_id_and_3_columns
        ON metrics_dashboard_annotations USING btree (cluster_id, dashboard_path, starting_at, ending_at)
        WHERE (cluster_id IS NOT NULL);

      CREATE INDEX index_metrics_dashboard_annotations_on_environment_id_and_3_col
        ON metrics_dashboard_annotations USING btree (environment_id, dashboard_path, starting_at, ending_at)
        WHERE (environment_id IS NOT NULL);

      CREATE INDEX index_metrics_dashboard_annotations_on_timespan_end
        ON metrics_dashboard_annotations USING btree (COALESCE(ending_at, starting_at));

      ALTER TABLE ONLY metrics_dashboard_annotations
        ADD CONSTRAINT fk_rails_345ab51043 FOREIGN KEY (cluster_id) REFERENCES clusters(id) ON DELETE CASCADE;

      ALTER TABLE ONLY metrics_dashboard_annotations
        ADD CONSTRAINT fk_rails_aeb11a7643 FOREIGN KEY (environment_id) REFERENCES environments(id) ON DELETE CASCADE;
    SQL
  end
end
