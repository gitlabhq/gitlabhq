# frozen_string_literal: true

class RemoveBrokenFkForPCiBuildsAndPCiPipelines < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers
  include Gitlab::Database::MigrationHelpers::WraparoundAutovacuum

  milestone '17.11'
  disable_ddl_transaction!

  SOURCE_TABLE_NAME = :p_ci_builds
  TARGET_TABLE_NAME = :p_ci_pipelines
  COLUMN = :auto_canceled_by_id
  TARGET_COLUMN = :id
  PARTITION_COLUMN = :auto_canceled_by_partition_id
  PARTITION_TARGET_COLUMN = :partition_id
  FK_NAME = :fk_a2141b1522_p

  def up
    # NOTE: autovacuum is run on partitions
    # ideally we should include the gitlab_partitions_dynamic.partitions
    # but these two partitions are the one that take long time for now
    return unless can_execute_on?(:ci_pipelines, :ci_builds)

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
    # NOTE: autovacuum is run on partitions
    # ideally we should include the gitlab_partitions_dynamic.partitions
    # but these two partitions are the one that take long time for now
    return unless can_execute_on?(:ci_pipelines, :ci_builds)

    add_concurrent_partitioned_foreign_key(
      SOURCE_TABLE_NAME,
      TARGET_TABLE_NAME,
      column: [PARTITION_COLUMN, COLUMN],
      target_column: [PARTITION_TARGET_COLUMN, TARGET_COLUMN],
      reverse_lock_order: true,
      on_update: :cascade,
      on_delete: :nullify,
      name: FK_NAME,
      validate: true
    )
  end
end
