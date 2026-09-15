# frozen_string_literal: true

class CreateMaterializedViewDuoWorkflowsWorkflowsEnrichedDeltaMv < ClickHouse::Migration
  def up
    # APPEND is load-bearing: without it a refresh atomically REPLACES the
    # whole target table instead of adding the delta rows.
    #
    # The scan window starts from max(_watermark) already in the target, so
    # missed refreshes extend the next window instead of losing data. On an
    # empty table the window opens at epoch, so the first refresh doubles as
    # the historical backfill.
    execute <<~SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS duo_workflows_workflows_enriched_delta_mv
      REFRESH EVERY 15 MINUTE APPEND TO duo_workflows_workflows_enriched
      AS
      WITH
        (
          SELECT max(_watermark) - INTERVAL 30 MINUTE FROM duo_workflows_workflows_enriched
        ) AS window_start,
        affected AS (
          SELECT DISTINCT id
          FROM (
            SELECT id
            FROM siphon_duo_workflows_workflows
            WHERE _siphon_watermark >= window_start
            UNION ALL
            SELECT workflow_id AS id
            FROM siphon_duo_workflows_workflow_merge_requests
            WHERE _siphon_watermark >= window_start
            UNION ALL
            SELECT workflow_id AS id
            FROM duo_workflow_session_enrichments
            WHERE updated_at >= window_start
          )
        ),
        wf AS (
          SELECT
            id,
            argMax(user_id, _siphon_replicated_at) AS user_id,
            argMax(project_id, _siphon_replicated_at) AS project_id,
            argMax(created_at, _siphon_replicated_at) AS created_at,
            argMax(updated_at, _siphon_replicated_at) AS updated_at,
            argMax(status, _siphon_replicated_at) AS status,
            argMax(goal, _siphon_replicated_at) AS goal,
            argMax(agent_privileges, _siphon_replicated_at) AS agent_privileges,
            argMax(workflow_definition, _siphon_replicated_at) AS workflow_definition,
            argMax(allow_agent_to_request_user, _siphon_replicated_at) AS allow_agent_to_request_user,
            argMax(pre_approved_agent_privileges, _siphon_replicated_at) AS pre_approved_agent_privileges,
            argMax(image, _siphon_replicated_at) AS image,
            argMax(environment, _siphon_replicated_at) AS environment,
            argMax(namespace_id, _siphon_replicated_at) AS namespace_id,
            argMax(ai_catalog_item_version_id, _siphon_replicated_at) AS ai_catalog_item_version_id,
            argMax(issue_id, _siphon_replicated_at) AS issue_id,
            argMax(merge_request_id, _siphon_replicated_at) AS merge_request_id,
            argMax(service_account_id, _siphon_replicated_at) AS service_account_id,
            argMax(tool_call_approvals, _siphon_replicated_at) AS tool_call_approvals,
            argMax(ai_catalog_item_id, _siphon_replicated_at) AS ai_catalog_item_id,
            argMax(traversal_path, _siphon_replicated_at) AS traversal_path,
            argMax(messaging_callback_context, _siphon_replicated_at) AS messaging_callback_context,
            argMax(summary, _siphon_replicated_at) AS summary,
            argMax(title, _siphon_replicated_at) AS title,
            argMax(incremental_checkpoints_enabled, _siphon_replicated_at) AS incremental_checkpoints_enabled,
            argMax(agent_type, _siphon_replicated_at) AS agent_type,
            argMax(jsonl_sha256, _siphon_replicated_at) AS jsonl_sha256,
            argMax(idempotency_key, _siphon_replicated_at) AS idempotency_key,
            argMax(sync_type, _siphon_replicated_at) AS sync_type,
            argMax(agent_identity_id, _siphon_replicated_at) AS agent_identity_id,
            argMax(web_search_enabled, _siphon_replicated_at) AS web_search_enabled,
            argMax(trigger_source, _siphon_replicated_at) AS trigger_source,
            argMax(trigger_flow_trigger_id, _siphon_replicated_at) AS trigger_flow_trigger_id,
            argMax(source_type, _siphon_replicated_at) AS source_type,
            argMax(source_link, _siphon_replicated_at) AS source_link,
            argMax(execution_mode, _siphon_replicated_at) AS execution_mode,
            argMax(_siphon_deleted, _siphon_replicated_at) AS _siphon_deleted,
            max(_siphon_replicated_at) AS wf_version,
            max(_siphon_watermark) AS wf_watermark
          FROM siphon_duo_workflows_workflows
          WHERE id IN (SELECT id FROM affected)
          GROUP BY id
        ),
        mr_links_cte AS (
          SELECT
            traversal_path,
            workflow_id,
            groupArrayIf(merge_request_id, link_type = 0 AND deleted = false) AS source_merge_request_ids,
            groupArrayIf(merge_request_id, link_type = 1 AND deleted = false) AS created_merge_request_ids,
            max(replicated_at) AS links_version,
            max(watermark) AS links_watermark
          FROM (
            SELECT
              traversal_path,
              workflow_id,
              merge_request_id,
              argMax(link_type, _siphon_replicated_at) AS link_type,
              argMax(_siphon_deleted, _siphon_replicated_at) AS deleted,
              max(_siphon_replicated_at) AS replicated_at,
              max(_siphon_watermark) AS watermark
            FROM siphon_duo_workflows_workflow_merge_requests
            WHERE (traversal_path, workflow_id) IN (SELECT traversal_path, id FROM wf)
            GROUP BY traversal_path, workflow_id, merge_request_id
          )
          GROUP BY traversal_path, workflow_id
        ),
        credits_cte AS (
          SELECT
            workflow_id,
            argMax(credits_used, updated_at) AS credits_used,
            argMax(model_used, updated_at) AS model_used,
            max(updated_at) AS credits_version
          FROM duo_workflow_session_enrichments
          WHERE workflow_id IN (SELECT id FROM wf)
          GROUP BY workflow_id
        ),
        current_state_cte AS (
          SELECT
            traversal_path,
            id,
            argMax(later_closed_merge_request_ids, _version) AS later_closed_merge_request_ids,
            argMax(later_merged_merge_request_ids, _version) AS later_merged_merge_request_ids
          FROM duo_workflows_workflows_enriched
          WHERE (traversal_path, id) IN (SELECT traversal_path, id FROM wf)
          GROUP BY traversal_path, id
        )
      SELECT
        wf.id AS id,
        wf.user_id AS user_id,
        wf.project_id AS project_id,
        wf.created_at AS created_at,
        wf.updated_at AS updated_at,
        wf.status AS status,
        wf.goal AS goal,
        wf.agent_privileges AS agent_privileges,
        wf.workflow_definition AS workflow_definition,
        wf.allow_agent_to_request_user AS allow_agent_to_request_user,
        wf.pre_approved_agent_privileges AS pre_approved_agent_privileges,
        wf.image AS image,
        wf.environment AS environment,
        wf.namespace_id AS namespace_id,
        wf.ai_catalog_item_version_id AS ai_catalog_item_version_id,
        wf.issue_id AS issue_id,
        wf.merge_request_id AS merge_request_id,
        wf.service_account_id AS service_account_id,
        wf.tool_call_approvals AS tool_call_approvals,
        wf.ai_catalog_item_id AS ai_catalog_item_id,
        wf.traversal_path AS traversal_path,
        wf.messaging_callback_context AS messaging_callback_context,
        wf.summary AS summary,
        wf.title AS title,
        wf.incremental_checkpoints_enabled AS incremental_checkpoints_enabled,
        wf.agent_type AS agent_type,
        wf.jsonl_sha256 AS jsonl_sha256,
        wf.idempotency_key AS idempotency_key,
        wf.sync_type AS sync_type,
        wf.agent_identity_id AS agent_identity_id,
        wf.web_search_enabled AS web_search_enabled,
        wf.trigger_source AS trigger_source,
        wf.trigger_flow_trigger_id AS trigger_flow_trigger_id,
        wf.source_type AS source_type,
        wf.source_link AS source_link,
        wf.execution_mode AS execution_mode,
        credits_cte.credits_used AS credits_used,
        credits_cte.model_used AS model_used,
        arraySort(mr_links_cte.source_merge_request_ids) AS source_merge_request_ids,
        arraySort(mr_links_cte.created_merge_request_ids) AS created_merge_request_ids,
        current_state_cte.later_closed_merge_request_ids AS later_closed_merge_request_ids,
        current_state_cte.later_merged_merge_request_ids AS later_merged_merge_request_ids,
        wf._siphon_deleted AS _siphon_deleted,
        greatest(
          wf.wf_version,
          coalesce(credits_cte.credits_version, toDateTime64(0, 6, 'UTC')),
          coalesce(mr_links_cte.links_version, toDateTime64(0, 6, 'UTC'))
        ) AS _version,
        greatest(
          wf.wf_watermark,
          coalesce(credits_cte.credits_version, toDateTime64(0, 6, 'UTC')),
          coalesce(mr_links_cte.links_watermark, toDateTime64(0, 6, 'UTC'))
        ) AS _watermark
      FROM wf
      LEFT JOIN credits_cte ON credits_cte.workflow_id = wf.id
      LEFT JOIN mr_links_cte ON mr_links_cte.traversal_path = wf.traversal_path AND
        mr_links_cte.workflow_id = wf.id
      LEFT JOIN current_state_cte ON current_state_cte.traversal_path = wf.traversal_path AND
        current_state_cte.id = wf.id
    SQL
  end

  def down
    execute 'DROP VIEW IF EXISTS duo_workflows_workflows_enriched_delta_mv'
  end
end
