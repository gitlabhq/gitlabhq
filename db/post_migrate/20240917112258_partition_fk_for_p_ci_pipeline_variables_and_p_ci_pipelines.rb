# frozen_string_literal: true

class PartitionFkForPCiPipelineVariablesAndPCiPipelines < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers

  milestone '17.5'
  disable_ddl_transaction!

  SOURCE_TABLE_NAME = :p_ci_pipeline_variables
  TARGET_TABLE_NAME = :p_ci_pipelines
  COLUMN = :pipeline_id
  TARGET_COLUMN = :id
  PARTITION_COLUMN = :partition_id
  FK_NAME = :fk_rails_507416c33a_p

  def up
    add_concurrent_partitioned_foreign_key(
      SOURCE_TABLE_NAME,
      TARGET_TABLE_NAME,
      column: [PARTITION_COLUMN, COLUMN],
      target_column: [PARTITION_COLUMN, TARGET_COLUMN],
      validate: false,
      reverse_lock_order: true,
      on_update: :cascade,
      on_delete: :cascade,
      name: FK_NAME
    )
  end

  def down
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
