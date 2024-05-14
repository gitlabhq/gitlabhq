# frozen_string_literal: true

class PartitionCiStagesAddFkToCiPipelines < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '16.10'
  disable_ddl_transaction!

  TABLE_NAME = :ci_stages
  PARENT_TABLE_NAME = :p_ci_stages
  FIRST_PARTITION = [100, 101]
  PARTITION_COLUMN = :partition_id
  BUILDS_TABLE = :p_ci_builds

  def up
    convert_table_to_first_list_partition(
      table_name: TABLE_NAME,
      partitioning_column: PARTITION_COLUMN,
      parent_table_name: PARENT_TABLE_NAME,
      initial_partitioning_value: FIRST_PARTITION
    )
  end

  def down
    # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- we're calling methods defined here
    with_lock_retries(raise_on_exhaustion: true) do
      drop_foreign_key

      execute(<<~SQL)
        ALTER TABLE #{PARENT_TABLE_NAME} DETACH PARTITION #{TABLE_NAME};
        ALTER SEQUENCE ci_stages_id_seq OWNED BY #{TABLE_NAME}.id;
      SQL

      drop_table(PARENT_TABLE_NAME)
    end
    # rubocop:enable Migration/WithLockRetriesDisallowedMethod

    add_routing_table_fk

    prepare_constraint_for_list_partitioning(
      table_name: TABLE_NAME,
      partitioning_column: PARTITION_COLUMN,
      parent_table_name: PARENT_TABLE_NAME,
      initial_partitioning_value: FIRST_PARTITION
    )
  end

  private

  def foreign_key
    @foreign_key ||= Gitlab::Database::PostgresForeignKey
      .by_constrained_table_name(BUILDS_TABLE)
      .by_referenced_table_name(TABLE_NAME)
      .first
  end

  def drop_foreign_key
    raise "Expected to find a foreign key between #{BUILDS_TABLE} and #{PARENT_TABLE_NAME}" unless foreign_key.present?

    remove_foreign_key_if_exists(BUILDS_TABLE, name: foreign_key.name)
  end

  def add_routing_table_fk
    add_concurrent_partitioned_foreign_key(
      BUILDS_TABLE,
      TABLE_NAME,
      column: [:partition_id, :stage_id],
      target_column: [:partition_id, :id],
      reverse_lock_order: true,
      on_update: :cascade,
      on_delete: :cascade,
      validate: true,
      name: foreign_key.name,
      allow_partitioned: true
    )
  end
end
