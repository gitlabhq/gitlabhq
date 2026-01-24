# frozen_string_literal: true

class CreateSiphonDeployments < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_deployments
      (
        id Int64,
        iid Int64,
        project_id Int64,
        environment_id Int64,
        ref String,
        tag Bool,
        sha String,
        user_id Nullable(Int64),
        deployable_type String DEFAULT '',
        created_at DateTime64(6, 'UTC') DEFAULT NOW(),
        updated_at DateTime64(6, 'UTC') DEFAULT NOW(),
        on_stop Nullable(String),
        status Int8,
        finished_at Nullable(DateTime64(6, 'UTC')),
        deployable_id Nullable(Int64),
        archived Bool DEFAULT false,
        traversal_path String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), '0/'),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now(),
        _siphon_deleted Bool DEFAULT FALSE,
        PROJECTION pg_pkey_ordered (
          SELECT *
          ORDER BY id
        )
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (traversal_path, id)
      SETTINGS deduplicate_merge_projection_mode = 'rebuild'
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_deployments
    SQL
  end
end
