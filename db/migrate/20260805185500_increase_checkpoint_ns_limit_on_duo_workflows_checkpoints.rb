# frozen_string_literal: true

class IncreaseCheckpointNsLimitOnDuoWorkflowsCheckpoints < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  disable_ddl_transaction!

  OLD_CONSTRAINT_NAME = 'check_duo_wf_checkpoints_checkpoint_ns_limit'
  NEW_CONSTRAINT_NAME = 'check_duo_wf_checkpoints_checkpoint_ns_limit_4k'

  # LangGraph composes `checkpoint_ns` as one `<node_name>:<task_uuid>` segment
  # per nested subgraph level, joined by `|` -- so it grows by
  # `node_name.length + 38` characters per level of subagent nesting. The
  # original 255-character limit capped nesting at ~4 levels for typical
  # subagent names (e.g. 4 x "research_agent" = 207 characters, 5 = 259).
  # 4096 removes that ceiling for any realistic nesting depth.
  def up
    add_text_limit :p_duo_workflows_checkpoints, :checkpoint_ns, 4096, constraint_name: NEW_CONSTRAINT_NAME

    remove_text_limit :p_duo_workflows_checkpoints, :checkpoint_ns, constraint_name: OLD_CONSTRAINT_NAME
  end

  def down
    # no-op: restoring the 255-character limit would fail if any row has since
    # been written with a longer checkpoint_ns.
  end
end
