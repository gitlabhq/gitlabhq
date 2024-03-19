# frozen_string_literal: true

class SwapColumnsForAutoCanceledByIdBetweenCiBuildsAndCiPipelines < Gitlab::Database::Migration[2.2]
  include ::Gitlab::Database::MigrationHelpers::Swapping
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '16.10'

  TABLE = :p_ci_builds
  REFERENCING_TABLE = :ci_pipelines
  NEW_COLUMN = :auto_canceled_by_id_convert_to_bigint
  OLD_COLUMN = :auto_canceled_by_id
  TRIGGER_FUNCTION = :trigger_10ee1357e825
  NEW_FK = :fk_dd3c83bdee
  OLD_FK = :fk_a2141b1522
  NEW_INDEX = :p_ci_builds_auto_canceled_by_id_bigint_idx
  NEW_INDEX_WHERE = 'auto_canceled_by_id_convert_to_bigint IS NOT NULL'
  OLD_INDEX = :p_ci_builds_auto_canceled_by_id_idx

  def up
    ensure_integer_partitioned_indexes_exist

    # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- custom implementation
    with_lock_retries(raise_on_exhaustion: true) do
      swap
      remove_integer_indexes_and_foreign_keys_and_rename_bigint
    end
    # rubocop:enable Migration/WithLockRetriesDisallowedMethod
  end

  def down
    recover_integer_indexes_and_foreign_keys

    # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- custom implementation
    with_lock_retries(raise_on_exhaustion: true) do
      swap
      swap_indexes_and_foreign_keys
    end
    # rubocop:enable Migration/WithLockRetriesDisallowedMethod
  end

  private

  def swap
    lock_tables(REFERENCING_TABLE, TABLE)

    swap_columns(TABLE, NEW_COLUMN, OLD_COLUMN)
    reset_trigger_function(TRIGGER_FUNCTION)
  end

  def remove_integer_indexes_and_foreign_keys_and_rename_bigint
    remove_foreign_key_if_exists(TABLE, REFERENCING_TABLE, name: OLD_FK, reverse_lock_order: true)

    partitioned_and_partitions do |table|
      rename_constraint(table, NEW_FK, OLD_FK)
    end

    partitioned_and_partition_indexes do |table, new_index, old_index, schema|
      swap_indexes(table, new_index, old_index, schema: schema)
    end

    remove_index(TABLE, name: NEW_INDEX) # rubocop:disable Migration/RemoveIndex -- same as remove_concurrent_partitioned_index_by_name
  end

  def swap_indexes_and_foreign_keys
    partitioned_and_partitions do |table|
      swap_foreign_keys(table, NEW_FK, OLD_FK)
    end

    partitioned_and_partition_indexes do |table, new_index, old_index, schema|
      swap_indexes(table, new_index, old_index, schema: schema)
    end
  end

  def partitioned_and_partitions
    Gitlab::Database::PostgresPartitionedTable.each_partition(TABLE) do |partition|
      yield(partition.identifier)
    end

    yield(TABLE)
  end

  def partitioned_and_partition_indexes
    new_index = indexes(TABLE).find { |i| i.name == NEW_INDEX.to_s }
    old_index = indexes(TABLE).find { |i| i.name == OLD_INDEX.to_s }

    Gitlab::Database::PostgresPartitionedTable.each_partition(TABLE) do |partition|
      table = partition.identifier
      new_partition_index_name = partition_index_for(table, new_index).name
      old_partition_index_name = partition_index_for(table, old_index).name

      yield(table, new_partition_index_name, old_partition_index_name, partition.schema)
    end

    yield(TABLE, NEW_INDEX, OLD_INDEX, nil)
  end

  def partition_index_for(partition_table, partitioned_index)
    partitioned_index_definition = partitioned_index.as_json.except('name', 'table', 'comment')

    indexes(partition_table).find do |definition|
      definition.as_json.except('name', 'table', 'comment') == partitioned_index_definition
    end
  end

  def ensure_integer_partitioned_indexes_exist
    with_lock_retries(raise_on_exhaustion: true) do
      found_index_name = index_name_for(TABLE, OLD_COLUMN)
      rename_index(TABLE, found_index_name, OLD_INDEX) unless found_index_name == OLD_INDEX.to_s
    end
  end

  def recover_integer_indexes_and_foreign_keys
    add_concurrent_partitioned_index(TABLE, [NEW_COLUMN], name: NEW_INDEX)

    add_concurrent_partitioned_foreign_key(
      TABLE, REFERENCING_TABLE,
      column: NEW_COLUMN, name: NEW_FK, on_delete: :nullify, reverse_lock_order: true
    )
  end

  def index_name_for(table, columns)
    index_columns = Array.wrap(columns).map(&:to_s)

    found_index = indexes(table).find do |index|
      index.columns == index_columns
    end
    found_index&.name
  end
end
