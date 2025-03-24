# frozen_string_literal: true

class RemoveBrokenFkF29c5f4380P < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers
  include Gitlab::Database::MigrationHelpers::WraparoundAutovacuum

  milestone '17.11'
  disable_ddl_transaction!

  SOURCE_TABLE_NAME = :p_ci_pipeline_variables
  TARGET_TABLE_NAME = :p_ci_pipelines
  COLUMN = :pipeline_id
  TARGET_COLUMN = :id
  PARTITION_COLUMN = :partition_id
  FK_NAME = :fk_f29c5f4380_p

  def up
    return unless can_execute_on?(:ci_pipelines, :ci_pipeline_variables)

    with_lock_retries do
      remove_foreign_key_if_exists(
        SOURCE_TABLE_NAME,
        TARGET_TABLE_NAME,
        name: FK_NAME,
        reverse_lock_order: true
      )
    end
  end

  def down
    return unless can_execute_on?(:ci_pipelines, :ci_pipeline_variables)

    add_concurrent_partitioned_foreign_key(
      SOURCE_TABLE_NAME,
      TARGET_TABLE_NAME,
      column: [PARTITION_COLUMN, COLUMN],
      target_column: [PARTITION_COLUMN, TARGET_COLUMN],
      reverse_lock_order: true,
      on_update: :cascade,
      on_delete: :cascade,
      name: FK_NAME,
      validate: true
    )
  end
end
