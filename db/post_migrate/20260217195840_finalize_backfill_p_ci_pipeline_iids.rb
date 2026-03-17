# frozen_string_literal: true

class FinalizeBackfillPCiPipelineIids < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  JOB_CLASS_NAME = 'BackfillPCiPipelineIids'
  TABLE_NAME = :p_ci_pipelines

  def up
    Gitlab::Database::PostgresPartitionedTable.each_partition(TABLE_NAME) do |partition|
      migration = Gitlab::Database::BackgroundMigration::BatchedMigration.find_for_configuration(
        gitlab_schema_from_context, JOB_CLASS_NAME, partition.identifier, :id, [],
        include_compatible: true
      )

      next unless migration

      ensure_batched_background_migration_is_finished(
        job_class_name: JOB_CLASS_NAME,
        table_name: partition.identifier,
        column_name: :id,
        job_arguments: [],
        finalize: true
      )
    end
  end

  def down
    # no-op
  end
end
