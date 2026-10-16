# frozen_string_literal: true

# Rows the delta MV emitted before the column existed read as NULL and, failed flows being
# terminal, never re-emit. Re-emit them once with the Siphon reason, stamped prev_version + 1us
# (the mr_outcomes rule) so the new row supersedes any repair. argMax(tuple(x)) keeps NULLs.
class BackfillDropReasonOnDuoWorkflowsWorkflowsEnriched < ClickHouse::Migration
  def up
    execute <<~SQL
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
        execution_mode, drop_reason, credits_used, model_used,
        source_merge_request_ids, created_merge_request_ids,
        later_closed_merge_request_ids, later_merged_merge_request_ids,
        _siphon_deleted, _version, _watermark
      )
      WITH
        reasons AS
        (
          SELECT id, argMax(tuple(drop_reason), _siphon_replicated_at).1 AS drop_reason
          FROM siphon_duo_workflows_workflows
          WHERE id IN (SELECT id FROM siphon_duo_workflows_workflows WHERE drop_reason IS NOT NULL)
          GROUP BY id
          HAVING drop_reason IS NOT NULL
        ),
        current AS
        (
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
            argMax(tuple(drop_reason), _version).1 AS current_drop_reason,
            argMax(credits_used, _version) AS credits_used,
            argMax(model_used, _version) AS model_used,
            argMax(source_merge_request_ids, _version) AS source_merge_request_ids,
            argMax(created_merge_request_ids, _version) AS created_merge_request_ids,
            argMax(later_closed_merge_request_ids, _version) AS later_closed_merge_request_ids,
            argMax(later_merged_merge_request_ids, _version) AS later_merged_merge_request_ids,
            argMax(_siphon_deleted, _version) AS _siphon_deleted,
            argMax(_watermark, _version) AS _watermark,
            max(_version) AS prev_version
          FROM duo_workflows_workflows_enriched
          WHERE id IN (SELECT id FROM reasons)
          GROUP BY traversal_path, created_at, id
          HAVING current_drop_reason IS NULL
        )
      SELECT
        current.id, current.user_id, current.project_id, current.created_at, current.updated_at,
        current.status, current.goal, current.agent_privileges, current.workflow_definition,
        current.allow_agent_to_request_user, current.pre_approved_agent_privileges, current.image,
        current.environment, current.namespace_id, current.ai_catalog_item_version_id,
        current.issue_id, current.merge_request_id, current.service_account_id,
        current.tool_call_approvals, current.ai_catalog_item_id, current.traversal_path,
        current.messaging_callback_context, current.summary, current.title,
        current.incremental_checkpoints_enabled, current.agent_type, current.jsonl_sha256,
        current.idempotency_key, current.sync_type, current.agent_identity_id,
        current.web_search_enabled, current.trigger_source, current.trigger_flow_trigger_id,
        current.source_type, current.source_link, current.execution_mode,
        reasons.drop_reason, current.credits_used, current.model_used,
        current.source_merge_request_ids, current.created_merge_request_ids,
        current.later_closed_merge_request_ids, current.later_merged_merge_request_ids,
        current._siphon_deleted,
        current.prev_version + toIntervalMicrosecond(1) AS _version,
        current._watermark
      FROM current
      INNER JOIN reasons ON reasons.id = current.id
    SQL
  end

  def down
    # no-op: the re-emitted rows differ from MV-emitted rows only by _version, so they cannot be
    # selectively removed. Re-running up is idempotent: rows that already carry a reason are skipped.
  end
end
