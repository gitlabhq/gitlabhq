# frozen_string_literal: true

class CreateSiphonEnvironments < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_environments
      (
        id Int64,
        project_id Int64,
        name String,
        created_at DateTime64(6, 'UTC') DEFAULT NOW(),
        updated_at DateTime64(6, 'UTC') DEFAULT NOW(),
        external_url Nullable(String),
        environment_type Nullable(String),
        state String DEFAULT 'available',
        slug String,
        auto_stop_at Nullable(DateTime64(6, 'UTC')),
        auto_delete_at Nullable(DateTime64(6, 'UTC')),
        tier Nullable(Int8),
        merge_request_id Nullable(Int64),
        cluster_agent_id Nullable(Int64),
        kubernetes_namespace Nullable(String),
        flux_resource_path Nullable(String),
        description Nullable(String),
        description_html Nullable(String),
        cached_markdown_version Nullable(Int64),
        auto_stop_setting Int8 DEFAULT 0,
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
      DROP TABLE IF EXISTS siphon_environments
    SQL
  end
end
