# frozen_string_literal: true

class AddAsyncFkUpstreamPipelineIdForPCiBuilds < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers

  milestone '17.3'
  disable_ddl_transaction!

  SOURCE_TABLE_NAME = :p_ci_builds
  TARGET_TABLE_NAME = :ci_pipelines
  COLUMN = :upstream_pipeline_id
  PARTITION_COLUMN = :upstream_pipeline_partition_id
  TARGET_COLUMN = :id
  TARGET_PARTITION_COLUMN = :partition_id
  FK_NAME = :fk_87f4cefcda_p

  def up
    add_concurrent_partitioned_foreign_key(
      SOURCE_TABLE_NAME,
      TARGET_TABLE_NAME,
      column: [PARTITION_COLUMN, COLUMN],
      target_column: [TARGET_PARTITION_COLUMN, TARGET_COLUMN],
      validate: false,
      reverse_lock_order: true,
      on_update: :cascade,
      on_delete: :cascade,
      name: FK_NAME
    )

    prepare_partitioned_async_foreign_key_validation(SOURCE_TABLE_NAME, [PARTITION_COLUMN, COLUMN], name: FK_NAME)
  end

  def down
    unprepare_partitioned_async_foreign_key_validation(SOURCE_TABLE_NAME, [PARTITION_COLUMN, COLUMN], name: FK_NAME)

    Gitlab::Database::PostgresPartitionedTable.each_partition(SOURCE_TABLE_NAME) do |partition|
      with_lock_retries do
        remove_foreign_key_if_exists(
          partition.identifier,
          TARGET_TABLE_NAME,
          name: FK_NAME,
          reverse_lock_order: true
        )
      end
    end
  end
end
