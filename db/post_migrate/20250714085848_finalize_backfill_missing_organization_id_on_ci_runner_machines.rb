# frozen_string_literal: true

class FinalizeBackfillMissingOrganizationIdOnCiRunnerMachines < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillMissingOrganizationIdOnCiRunnerMachines',
      table_name: :ci_runner_machines,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
