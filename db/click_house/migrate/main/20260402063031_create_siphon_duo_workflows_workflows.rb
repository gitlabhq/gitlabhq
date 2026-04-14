# frozen_string_literal: true

class CreateSiphonDuoWorkflowsWorkflows < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_duo_workflows_workflows
      (
        id Int64 CODEC(DoubleDelta, ZSTD),
        user_id Int64,
        project_id Nullable(Int64),
        created_at DateTime64(6, 'UTC') CODEC(Delta, ZSTD(1)),
        updated_at DateTime64(6, 'UTC') CODEC(Delta, ZSTD(1)),
        status Int16 DEFAULT 0,
        goal Nullable(String),
        agent_privileges Array(Int16) DEFAULT [],
        workflow_definition String DEFAULT 'software_development',
        allow_agent_to_request_user Bool DEFAULT true,
        pre_approved_agent_privileges Array(Int16) DEFAULT [],
        image Nullable(String),
        environment Nullable(Int16),
        namespace_id Nullable(Int64),
        ai_catalog_item_version_id Nullable(Int64),
        issue_id Nullable(Int64),
        merge_request_id Nullable(Int64),
        service_account_id Nullable(Int64),
        tool_call_approvals String DEFAULT '{}',
        ai_catalog_item_id Nullable(Int64),
        traversal_path String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), coalesce(namespace_id, 0) != 0, dictGetOrDefault('namespace_traversal_paths_dict', 'traversal_path', namespace_id, '0/'), '0/') CODEC(ZSTD(3)),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
        _siphon_deleted Bool DEFAULT FALSE CODEC(ZSTD(1)),
        PROJECTION pg_pkey_ordered (
          SELECT *
          ORDER BY id
        )
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (traversal_path, created_at, id)
      SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild'
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_duo_workflows_workflows
    SQL
  end
end
