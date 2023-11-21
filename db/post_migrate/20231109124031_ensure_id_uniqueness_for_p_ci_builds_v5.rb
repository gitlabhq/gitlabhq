# frozen_string_literal: true

class EnsureIdUniquenessForPCiBuildsV5 < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::SchemaHelpers

  enable_lock_retries!
  milestone '16.7'

  TABLE_NAME = :p_ci_builds
  FUNCTION_NAME = :assign_p_ci_builds_id_value
  TRIGGER_NAME = :assign_p_ci_builds_id_trigger

  def up
    return if trigger_exists?(TABLE_NAME, TRIGGER_NAME)

    lock_tables(TABLE_NAME, :ci_builds)

    Gitlab::Database::PostgresPartitionedTable.each_partition(TABLE_NAME) do |partition|
      drop_trigger(partition.identifier, TRIGGER_NAME, if_exists: true)
    end

    create_trigger(TABLE_NAME, TRIGGER_NAME, FUNCTION_NAME, fires: 'BEFORE INSERT')
  end

  def down
    drop_trigger(TABLE_NAME, TRIGGER_NAME, if_exists: true)
    return if trigger_exists?(:ci_builds, TRIGGER_NAME)

    Gitlab::Database::PostgresPartitionedTable.each_partition(TABLE_NAME) do |partition|
      create_trigger(partition.identifier, TRIGGER_NAME, FUNCTION_NAME, fires: 'BEFORE INSERT')
    end
  end
end
