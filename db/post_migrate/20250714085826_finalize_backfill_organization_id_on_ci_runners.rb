# frozen_string_literal: true

class FinalizeBackfillOrganizationIdOnCiRunners < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillOrganizationIdOnCiRunners',
      table_name: :ci_runners,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
