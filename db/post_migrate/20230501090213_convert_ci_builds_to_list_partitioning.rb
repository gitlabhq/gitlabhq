# frozen_string_literal: true

class ConvertCiBuildsToListPartitioning < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!

  TABLE_NAME = :ci_builds
  PARENT_TABLE_NAME = :p_ci_builds
  FIRST_PARTITION = 100
  PARTITION_COLUMN = :partition_id
  FOREIGN_KEYS = {
    p_ci_builds_metadata: :fk_e20479742e_p,
    p_ci_runner_machine_builds: :fk_bb490f12fe_p
  }

  def up
    convert_table_to_first_list_partition(
      table_name: TABLE_NAME,
      partitioning_column: PARTITION_COLUMN,
      parent_table_name: PARENT_TABLE_NAME,
      initial_partitioning_value: FIRST_PARTITION,
      lock_tables: %w[ci_pipelines ci_stages ci_builds ci_resource_groups]
    )
  end

  def down
    # rubocop:disable Migration/WithLockRetriesDisallowedMethod
    with_lock_retries(raise_on_exhaustion: true) do
      drop_foreign_keys

      execute(<<~SQL)
        ALTER TABLE #{PARENT_TABLE_NAME} DETACH PARTITION #{TABLE_NAME};
        ALTER SEQUENCE ci_builds_id_seq OWNED BY #{TABLE_NAME}.id;
      SQL

      drop_table PARENT_TABLE_NAME
      recreate_partition_foreign_keys
    end
    # rubocop:enable Migration/WithLockRetriesDisallowedMethod

    finalize_foreign_keys_creation

    prepare_constraint_for_list_partitioning(
      table_name: TABLE_NAME,
      partitioning_column: PARTITION_COLUMN,
      parent_table_name: PARENT_TABLE_NAME,
      initial_partitioning_value: FIRST_PARTITION
    )
  end

  private

  def drop_foreign_keys
    FOREIGN_KEYS.each do |source, name|
      remove_foreign_key_if_exists source, name: name
    end
  end

  def recreate_partition_foreign_keys
    FOREIGN_KEYS.each do |source, name|
      Gitlab::Database::PostgresPartitionedTable.each_partition(source) do |partition|
        execute(<<~SQL)
          ALTER TABLE #{partition.identifier}
            ADD CONSTRAINT #{name} FOREIGN KEY (partition_id, build_id)
            REFERENCES #{TABLE_NAME}(partition_id, id)
            ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;
        SQL
      end
    end
  end

  def finalize_foreign_keys_creation
    FOREIGN_KEYS.each do |source, name|
      add_concurrent_partitioned_foreign_key(source, TABLE_NAME,
        column: [:partition_id, :build_id],
        target_column: [:partition_id, :id],
        reverse_lock_order: true,
        on_update: :cascade,
        on_delete: :cascade,
        name: name
      )
    end
  end
end
