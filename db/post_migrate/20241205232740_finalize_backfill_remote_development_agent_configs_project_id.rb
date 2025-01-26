# frozen_string_literal: true

class FinalizeBackfillRemoteDevelopmentAgentConfigsProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillRemoteDevelopmentAgentConfigsProjectId',
      table_name: :remote_development_agent_configs,
      column_name: :id,
      job_arguments: [:project_id, :cluster_agents, :project_id, :cluster_agent_id],
      finalize: true
    )
  end

  def down; end
end
