# frozen_string_literal: true

class NewFkForPCiBuildsExecutionConfigsAndPCiPipelines2 < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers

  milestone '17.7'
  disable_ddl_transaction!

  SOURCE_TABLE_NAME = :p_ci_builds_execution_configs
  TARGET_TABLE_NAME = :p_ci_pipelines
  COLUMN = :pipeline_id
  TARGET_COLUMN = :id
  PARTITION_COLUMN = :partition_id
  FK_NAME = :fk_rails_bc9ff5d0a9_p

  def up
    options = {
      column: [PARTITION_COLUMN, COLUMN],
      target_column: [PARTITION_COLUMN, TARGET_COLUMN],
      validate: false,
      reverse_lock_order: true,
      on_update: :cascade,
      on_delete: :cascade,
      name: FK_NAME
    }

    Gitlab::Database::PostgresPartitionedTable.each_partition(SOURCE_TABLE_NAME).to_a.reverse_each do |partition|
      add_concurrent_foreign_key(partition.identifier, TARGET_TABLE_NAME, **options)
    end
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
