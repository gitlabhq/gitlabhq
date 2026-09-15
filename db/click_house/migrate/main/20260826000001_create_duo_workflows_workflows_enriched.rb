# frozen_string_literal: true

class CreateDuoWorkflowsWorkflowsEnriched < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS duo_workflows_workflows_enriched
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
        traversal_path String CODEC(ZSTD(3)),
        messaging_callback_context Nullable(String),
        summary Nullable(String),
        title Nullable(String),
        incremental_checkpoints_enabled Nullable(Bool),
        agent_type Nullable(String),
        jsonl_sha256 Nullable(String),
        idempotency_key Nullable(String),
        sync_type Nullable(Int16),
        agent_identity_id Nullable(Int64),
        web_search_enabled Bool DEFAULT false,
        trigger_source Int16 DEFAULT 0,
        trigger_flow_trigger_id Nullable(Int64),
        source_type Nullable(Int16),
        source_link Nullable(String),
        execution_mode Nullable(Int16),
        credits_used Float64 DEFAULT 0,
        model_used LowCardinality(String) DEFAULT '',
        source_merge_request_ids Array(Int64) DEFAULT [],
        created_merge_request_ids Array(Int64) DEFAULT [],
        later_closed_merge_request_ids Array(Int64) DEFAULT [],
        later_merged_merge_request_ids Array(Int64) DEFAULT [],
        _siphon_deleted Bool DEFAULT false CODEC(ZSTD(1)),
        _version DateTime64(6, 'UTC') CODEC(ZSTD(1)),
        _watermark DateTime64(6, 'UTC') CODEC(ZSTD(1))
      )
      ENGINE = ReplacingMergeTree(_version, _siphon_deleted)
      PRIMARY KEY (traversal_path, created_at, id)
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS duo_workflows_workflows_enriched
    SQL
  end
end
