# frozen_string_literal: true

class RevertFkCiPipelinesPCiBuildsOnPartitionIdUpstreamPipelineId < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers

  milestone '17.2'
  disable_ddl_transaction!

  SOURCE_TABLE_NAME = :p_ci_builds
  TARGET_TABLE_NAME = :ci_pipelines
  COLUMN = :upstream_pipeline_id
  TARGET_COLUMN = :id
  FK_NAME = :fk_87f4cefcda_p
  PARTITION_COLUMN = :partition_id

  def up
    unprepare_partitioned_async_foreign_key_validation(
      SOURCE_TABLE_NAME,
      [PARTITION_COLUMN, COLUMN],
      name: FK_NAME
    )

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

  def down; end
end
