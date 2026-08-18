# frozen_string_literal: true

class AddCheckpointNsToDuoWorkflowsCheckpointHeaders < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_duo_wf_checkpoint_headers_checkpoint_ns_limit'

  # Mirrors the checkpoint_ns column on p_duo_workflows_checkpoints, which
  # p_duo_workflows_checkpoint_headers replaces (gitlab-org/gitlab#605653). The
  # limit is 4096 rather than the 255 that table was created with: LangGraph
  # composes checkpoint_ns as one `<node_name>:<task_uuid>` segment per nested
  # subgraph level, so 255 caps delegated-subagent nesting at ~4 levels. See
  # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/248916, which raises
  # the checkpoints table to the same 4096.
  def up
    add_column :p_duo_workflows_checkpoint_headers, :checkpoint_ns, :text, if_not_exists: true

    add_text_limit :p_duo_workflows_checkpoint_headers, :checkpoint_ns, 4096, constraint_name: CONSTRAINT_NAME
  end

  def down
    remove_column :p_duo_workflows_checkpoint_headers, :checkpoint_ns, if_exists: true
  end
end
