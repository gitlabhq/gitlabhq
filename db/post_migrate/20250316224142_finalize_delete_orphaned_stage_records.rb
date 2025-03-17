# frozen_string_literal: true

class FinalizeDeleteOrphanedStageRecords < Gitlab::Database::Migration[2.2]
  milestone '17.11'
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = 'DeleteOrphanedStageRecords'

  def up
    force_finish if Gitlab.com_except_jh?
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: :p_ci_stages,
      column_name: :pipeline_id,
      job_arguments: [],
      finalize: true
    )
  end

  def down
    # no-op
  end

  private

  def force_finish
    Gitlab::Database::BackgroundMigration::BatchedMigration.reset_column_information
    migration = Gitlab::Database::BackgroundMigration::BatchedMigration.find_for_configuration(
      gitlab_schema_from_context,
      MIGRATION, :p_ci_stages, :pipeline_id, [],
      include_compatible: true
    )
    return unless migration

    migration.update_columns(
      status: Gitlab::Database::BackgroundMigration::BatchedMigration.state_machines[:status].states[:finished].value
    )
  end
end
