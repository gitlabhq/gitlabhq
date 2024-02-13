# frozen_string_literal: true

class PartitionCiJobArtifactsAddFkToCiBuilds < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  milestone '16.10'
  disable_ddl_transaction!

  TABLE_NAME = :ci_job_artifacts
  PARENT_TABLE_NAME = :p_ci_job_artifacts
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
        ALTER SEQUENCE ci_job_artifacts_id_seq OWNED BY #{TABLE_NAME}.id;
      SQL

      drop_table PARENT_TABLE_NAME
      recreate_foreign_key
    end
    # rubocop:enable Migration/WithLockRetriesDisallowedMethod

    finalize_foreign_key_creation

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
      .by_constrained_table_name(PARENT_TABLE_NAME)
      .by_referenced_table_name(BUILDS_TABLE)
      .first
  end

  def drop_foreign_key
    raise "Expected to find a foreign key between #{PARENT_TABLE_NAME} and #{BUILDS_TABLE}" unless foreign_key.present?

    remove_foreign_key_if_exists PARENT_TABLE_NAME, name: foreign_key.name
  end

  def recreate_foreign_key
    execute(<<~SQL)
      ALTER TABLE #{TABLE_NAME}
        ADD CONSTRAINT #{foreign_key.name} FOREIGN KEY (partition_id, job_id)
        REFERENCES #{BUILDS_TABLE}(partition_id, id)
        ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;
    SQL
  end

  def finalize_foreign_key_creation
    fk = foreign_key || new_foreign_key
    validate_foreign_key TABLE_NAME, nil, name: fk.name
  end

  def new_foreign_key
    Gitlab::Database::PostgresForeignKey
      .by_constrained_table_name(TABLE_NAME)
      .by_referenced_table_name(BUILDS_TABLE)
      .first
  end
end
