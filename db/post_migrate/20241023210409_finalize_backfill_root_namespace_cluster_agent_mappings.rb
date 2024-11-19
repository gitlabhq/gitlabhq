# frozen_string_literal: true

class FinalizeBackfillRootNamespaceClusterAgentMappings < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  MIGRATION = 'BackfillRootNamespaceClusterAgentMappings'
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: :remote_development_agent_configs,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down
    # no-op
  end
end
