# frozen_string_literal: true

class FinalizeDeduplicatePipelineIids < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  JOB_CLASS_NAME = 'DeduplicatePipelineIids'
  TABLE_NAME = :p_ci_pipelines

  # The queue migration created one BBM per physical partition, skipping empty partitions and, on
  # GitLab.com, those holding no duplicates (partition_id > 107). So partitions with no record are
  # expected, and job_arguments must repeat the partition's own ids for the lookup to match.
  def up
    Gitlab::Database::PostgresPartitionedTable.each_partition(TABLE_NAME) do |partition|
      job_arguments = [partition.list_partition_ids]

      migration = Gitlab::Database::BackgroundMigration::BatchedMigration.find_for_configuration(
        gitlab_schema_from_context, JOB_CLASS_NAME, partition.identifier, :id, job_arguments,
        include_compatible: true
      )

      next unless migration

      ensure_batched_background_migration_is_finished(
        job_class_name: JOB_CLASS_NAME,
        table_name: partition.identifier,
        column_name: :id,
        job_arguments: job_arguments,
        finalize: true
      )
    end
  end

  def down
    # no-op: finalizing a batched background migration is not reversible.
  end
end
