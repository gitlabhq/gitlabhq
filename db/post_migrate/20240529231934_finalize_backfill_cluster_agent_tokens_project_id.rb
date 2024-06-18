# frozen_string_literal: true

class FinalizeBackfillClusterAgentTokensProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillClusterAgentTokensProjectId',
      table_name: :cluster_agent_tokens,
      column_name: :id,
      job_arguments: [:project_id, :cluster_agents, :project_id, :agent_id],
      finalize: true
    )
  end

  def down; end
end
