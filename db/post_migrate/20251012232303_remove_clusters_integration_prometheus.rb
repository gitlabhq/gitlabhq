# frozen_string_literal: true

class RemoveClustersIntegrationPrometheus < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  def up
    drop_table :clusters_integration_prometheus
  end

  def down
    execute <<~SQL
      CREATE TABLE clusters_integration_prometheus (
        created_at timestamp with time zone NOT NULL,
        updated_at timestamp with time zone NOT NULL,
        cluster_id bigint NOT NULL,
        enabled boolean DEFAULT false NOT NULL,
        encrypted_alert_manager_token text,
        encrypted_alert_manager_token_iv text,
        health_status smallint DEFAULT 0 NOT NULL
      );

      ALTER TABLE ONLY clusters_integration_prometheus
        ADD CONSTRAINT clusters_integration_prometheus_pkey PRIMARY KEY (cluster_id);

      CREATE INDEX index_clusters_integration_prometheus_enabled
        ON clusters_integration_prometheus USING btree (enabled, created_at, cluster_id);
    SQL
  end
end
