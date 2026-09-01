# frozen_string_literal: true

class CreateMaterializedViewDuoWorkflowsWorkflowsEnrichedMrOutcomesMv < ClickHouse::Migration
  def up
    # APPEND is load-bearing: without it a refresh atomically REPLACES the
    # whole target table, wiping the rows owned by the delta MV.
    #
    # _version is stamped prev_version + 1us (not now64()): the repaired row
    # must supersede the state it read, but lose to any newer source-derived
    # emit from the delta MV, which carries later_* forward anyway.
    execute <<~SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS duo_workflows_workflows_enriched_mr_outcomes_mv
      REFRESH EVERY 12 HOUR APPEND TO duo_workflows_workflows_enriched
      AS
      WITH
        unresolved AS (
          SELECT
            traversal_path,
            created_at,
            id,
            argMax(user_id, _version) AS user_id,
            argMax(project_id, _version) AS project_id,
            argMax(updated_at, _version) AS updated_at,
            argMax(status, _version) AS status,
            argMax(goal, _version) AS goal,
            argMax(agent_privileges, _version) AS agent_privileges,
            argMax(workflow_definition, _version) AS workflow_definition,
            argMax(allow_agent_to_request_user, _version) AS allow_agent_to_request_user,
            argMax(pre_approved_agent_privileges, _version) AS pre_approved_agent_privileges,
            argMax(image, _version) AS image,
            argMax(environment, _version) AS environment,
            argMax(namespace_id, _version) AS namespace_id,
            argMax(ai_catalog_item_version_id, _version) AS ai_catalog_item_version_id,
            argMax(issue_id, _version) AS issue_id,
            argMax(merge_request_id, _version) AS merge_request_id,
            argMax(service_account_id, _version) AS service_account_id,
            argMax(tool_call_approvals, _version) AS tool_call_approvals,
            argMax(ai_catalog_item_id, _version) AS ai_catalog_item_id,
            argMax(messaging_callback_context, _version) AS messaging_callback_context,
            argMax(summary, _version) AS summary,
            argMax(title, _version) AS title,
            argMax(incremental_checkpoints_enabled, _version) AS incremental_checkpoints_enabled,
            argMax(agent_type, _version) AS agent_type,
            argMax(jsonl_sha256, _version) AS jsonl_sha256,
            argMax(idempotency_key, _version) AS idempotency_key,
            argMax(sync_type, _version) AS sync_type,
            argMax(agent_identity_id, _version) AS agent_identity_id,
            argMax(web_search_enabled, _version) AS web_search_enabled,
            argMax(trigger_source, _version) AS trigger_source,
            argMax(trigger_flow_trigger_id, _version) AS trigger_flow_trigger_id,
            argMax(source_type, _version) AS source_type,
            argMax(source_link, _version) AS source_link,
            argMax(execution_mode, _version) AS execution_mode,
            argMax(credits_used, _version) AS credits_used,
            argMax(model_used, _version) AS model_used,
            argMax(source_merge_request_ids, _version) AS source_merge_request_ids,
            argMax(created_merge_request_ids, _version) AS created_merge_request_ids,
            argMax(later_closed_merge_request_ids, _version) AS old_later_closed,
            argMax(later_merged_merge_request_ids, _version) AS old_later_merged,
            argMax(_siphon_deleted, _version) AS _siphon_deleted,
            argMax(_watermark, _version) AS _watermark,
            max(_version) AS prev_version
          FROM duo_workflows_workflows_enriched
          WHERE _version >= now64(6, 'UTC') - INTERVAL 60 DAY
          GROUP BY traversal_path, created_at, id
          HAVING _siphon_deleted = false
            AND notEmpty(arrayFilter(
              mr_id -> NOT has(old_later_closed, mr_id) AND NOT has(old_later_merged, mr_id),
              created_merge_request_ids))
        ),
        (
          SELECT
            (groupArrayIf(mr_id, state_id = 2), groupArrayIf(mr_id, state_id = 3))
          FROM (
            SELECT
              id AS mr_id,
              argMax(state_id, _siphon_replicated_at) AS state_id,
              argMax(_siphon_deleted, _siphon_replicated_at) AS mr_deleted
            FROM merge_requests
            WHERE id IN (
              SELECT DISTINCT arrayJoin(created_merge_request_ids)
              FROM duo_workflows_workflows_enriched
              WHERE _version >= now64(6, 'UTC') - INTERVAL 60 DAY
            )
            GROUP BY id
            HAVING mr_deleted = false AND state_id IN (2, 3)
          )
        ) AS resolved_mr_ids
      SELECT
        unresolved.traversal_path AS traversal_path,
        unresolved.created_at AS created_at,
        unresolved.id AS id,
        unresolved.user_id AS user_id,
        unresolved.project_id AS project_id,
        unresolved.updated_at AS updated_at,
        unresolved.status AS status,
        unresolved.goal AS goal,
        unresolved.agent_privileges AS agent_privileges,
        unresolved.workflow_definition AS workflow_definition,
        unresolved.allow_agent_to_request_user AS allow_agent_to_request_user,
        unresolved.pre_approved_agent_privileges AS pre_approved_agent_privileges,
        unresolved.image AS image,
        unresolved.environment AS environment,
        unresolved.namespace_id AS namespace_id,
        unresolved.ai_catalog_item_version_id AS ai_catalog_item_version_id,
        unresolved.issue_id AS issue_id,
        unresolved.merge_request_id AS merge_request_id,
        unresolved.service_account_id AS service_account_id,
        unresolved.tool_call_approvals AS tool_call_approvals,
        unresolved.ai_catalog_item_id AS ai_catalog_item_id,
        unresolved.messaging_callback_context AS messaging_callback_context,
        unresolved.summary AS summary,
        unresolved.title AS title,
        unresolved.incremental_checkpoints_enabled AS incremental_checkpoints_enabled,
        unresolved.agent_type AS agent_type,
        unresolved.jsonl_sha256 AS jsonl_sha256,
        unresolved.idempotency_key AS idempotency_key,
        unresolved.sync_type AS sync_type,
        unresolved.agent_identity_id AS agent_identity_id,
        unresolved.web_search_enabled AS web_search_enabled,
        unresolved.trigger_source AS trigger_source,
        unresolved.trigger_flow_trigger_id AS trigger_flow_trigger_id,
        unresolved.source_type AS source_type,
        unresolved.source_link AS source_link,
        unresolved.execution_mode AS execution_mode,
        unresolved.credits_used AS credits_used,
        unresolved.model_used AS model_used,
        unresolved.source_merge_request_ids AS source_merge_request_ids,
        unresolved.created_merge_request_ids AS created_merge_request_ids,
        arraySort(arrayIntersect(created_merge_request_ids, resolved_mr_ids.1)) AS later_closed_merge_request_ids,
        arraySort(arrayIntersect(created_merge_request_ids, resolved_mr_ids.2)) AS later_merged_merge_request_ids,
        unresolved._siphon_deleted AS _siphon_deleted,
        unresolved.prev_version + toIntervalMicrosecond(1) AS _version,
        unresolved._watermark AS _watermark
      FROM unresolved
      WHERE later_closed_merge_request_ids != arraySort(old_later_closed)
         OR later_merged_merge_request_ids != arraySort(old_later_merged)
      SETTINGS optimize_aggregation_in_order = 1
    SQL
  end

  def down
    execute 'DROP VIEW IF EXISTS duo_workflows_workflows_enriched_mr_outcomes_mv'
  end
end
