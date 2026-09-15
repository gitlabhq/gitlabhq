# frozen_string_literal: true

class BackfillDuoWorkflowsWorkflowsEnriched < ClickHouse::Migration
  BATCH_SIZE = 100_000

  def up
    builder = ClickHouse::Client::QueryBuilder.new('siphon_duo_workflows_workflows')
    iterator = ClickHouse::Iterator.new(query_builder: builder, connection: connection)

    iterator.each_batch(column: :id, of: BATCH_SIZE) do |_scope, min_id, max_id|
      execute(insert_sql(min_id, max_id))
    end
  end

  def down
    # no-op: backfilled rows carry source-derived _version values and are not
    # distinguishable from MV-emitted rows, so they cannot be selectively
    # deleted. Re-running the backfill is idempotent (ReplacingMergeTree
    # collapses duplicate versions), so no cleanup is needed before a retry.
  end

  private

  # Mirrors the SELECT of duo_workflows_workflows_enriched_delta_mv so that
  # backfilled rows carry the same _version/_watermark a delta refresh would
  # emit. Stamping _watermark keeps the first delta refresh window small
  # instead of re-scanning from epoch. later_* columns are left to their []
  # defaults; the mr_outcomes MV fills them in.
  def insert_sql(min_id, max_id)
    <<~SQL
      INSERT INTO duo_workflows_workflows_enriched
      (
        id, user_id, project_id, created_at, updated_at, status, goal,
        agent_privileges, workflow_definition, allow_agent_to_request_user,
        pre_approved_agent_privileges, image, environment, namespace_id,
        ai_catalog_item_version_id, issue_id, merge_request_id,
        service_account_id, tool_call_approvals, ai_catalog_item_id,
        traversal_path, messaging_callback_context, summary, title,
        incremental_checkpoints_enabled, agent_type, jsonl_sha256,
        idempotency_key, sync_type, agent_identity_id, web_search_enabled,
        trigger_source, trigger_flow_trigger_id, source_type, source_link,
        execution_mode, credits_used, model_used, source_merge_request_ids,
        created_merge_request_ids, _siphon_deleted, _version, _watermark
      )
      WITH
        base AS (
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
          WHERE id >= #{Integer(min_id)} AND id <= #{Integer(max_id)}
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
            WHERE (traversal_path, workflow_id) IN (SELECT traversal_path, id FROM base)
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
          WHERE workflow_id IN (SELECT id FROM base)
          GROUP BY workflow_id
        )
      SELECT
        base.id,
        base.user_id,
        base.project_id,
        base.created_at,
        base.updated_at,
        base.status,
        base.goal,
        base.agent_privileges,
        base.workflow_definition,
        base.allow_agent_to_request_user,
        base.pre_approved_agent_privileges,
        base.image,
        base.environment,
        base.namespace_id,
        base.ai_catalog_item_version_id,
        base.issue_id,
        base.merge_request_id,
        base.service_account_id,
        base.tool_call_approvals,
        base.ai_catalog_item_id,
        base.traversal_path,
        base.messaging_callback_context,
        base.summary,
        base.title,
        base.incremental_checkpoints_enabled,
        base.agent_type,
        base.jsonl_sha256,
        base.idempotency_key,
        base.sync_type,
        base.agent_identity_id,
        base.web_search_enabled,
        base.trigger_source,
        base.trigger_flow_trigger_id,
        base.source_type,
        base.source_link,
        base.execution_mode,
        credits_cte.credits_used,
        credits_cte.model_used,
        arraySort(mr_links_cte.source_merge_request_ids),
        arraySort(mr_links_cte.created_merge_request_ids),
        base._siphon_deleted,
        greatest(
          base.wf_version,
          coalesce(credits_cte.credits_version, toDateTime64(0, 6, 'UTC')),
          coalesce(mr_links_cte.links_version, toDateTime64(0, 6, 'UTC'))
        ),
        greatest(
          base.wf_watermark,
          coalesce(credits_cte.credits_version, toDateTime64(0, 6, 'UTC')),
          coalesce(mr_links_cte.links_watermark, toDateTime64(0, 6, 'UTC'))
        )
      FROM base
      LEFT JOIN credits_cte ON credits_cte.workflow_id = base.id
      LEFT JOIN mr_links_cte ON mr_links_cte.traversal_path = base.traversal_path AND
        mr_links_cte.workflow_id = base.id
    SQL
  end
end
