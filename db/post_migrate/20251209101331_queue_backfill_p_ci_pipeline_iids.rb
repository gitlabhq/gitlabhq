# frozen_string_literal: true

class QueueBackfillPCiPipelineIids < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = 'BackfillPCiPipelineIids'
  BATCH_SIZE = 10_000
  SUB_BATCH_SIZE = 1_000
  TABLE_NAME = :p_ci_pipelines

  def up
    Gitlab::Database::PostgresPartitionedTable.each_partition(TABLE_NAME) do |partition|
      next if empty_partition?(partition)

      queue_batched_background_migration(
        MIGRATION,
        partition.identifier,
        :id,
        batch_size: BATCH_SIZE,
        sub_batch_size: SUB_BATCH_SIZE
      )
    end
  end

  def down
    Gitlab::Database::PostgresPartitionedTable.each_partition(TABLE_NAME) do |partition|
      delete_batched_background_migration(MIGRATION, partition.identifier, :id, [])
    end
  end

  private

  def empty_partition?(partition)
    !connection.select_value("SELECT true FROM #{partition.identifier} LIMIT 1")
  end

  # Workaround to allow a single migration to enqueue multiple background migrations
  def assign_attributes_safely(migration, max_batch_size, batch_table_name, gitlab_schema, _queued_migration_version)
    super(migration, max_batch_size, batch_table_name, gitlab_schema, nil)
  end
end
