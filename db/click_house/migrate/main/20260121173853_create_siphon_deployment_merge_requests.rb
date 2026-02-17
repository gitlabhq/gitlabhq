# frozen_string_literal: true

class CreateSiphonDeploymentMergeRequests < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_deployment_merge_requests
      (
        deployment_id Int64,
        merge_request_id Int64,
        environment_id Nullable(Int64),
        project_id Int64,
        traversal_path String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), '0/'),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now(),
        _siphon_deleted Bool DEFAULT FALSE,
        PROJECTION pg_pkey_ordered (
          SELECT *
          ORDER BY deployment_id, merge_request_id
        )
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (traversal_path, deployment_id, merge_request_id)
      SETTINGS deduplicate_merge_projection_mode = 'rebuild'
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_deployment_merge_requests
    SQL
  end
end
