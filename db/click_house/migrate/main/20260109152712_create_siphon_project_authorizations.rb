# frozen_string_literal: true

class CreateSiphonProjectAuthorizations < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_project_authorizations
      (
        user_id Int64,
        project_id Int64,
        access_level Int64,
        is_unique Nullable(Bool),
        traversal_path String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), '0/'),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now(),
        _siphon_deleted Bool DEFAULT FALSE,
        PROJECTION pg_pkey_ordered (
          SELECT *
          ORDER BY user_id, project_id, access_level
        )
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (traversal_path, user_id, project_id, access_level)
      SETTINGS deduplicate_merge_projection_mode = 'rebuild'
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_project_authorizations
    SQL
  end
end
