# frozen_string_literal: true

class EnsureIdUniquenessForPCiBuildsV4 < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::SchemaHelpers
  include Gitlab::Database::MigrationHelpers::WraparoundAutovacuum

  enable_lock_retries!
  milestone '16.7'

  TABLE_NAME = :p_ci_builds
  FUNCTION_NAME = :assign_p_ci_builds_id_value
  TRIGGER_NAME = :assign_p_ci_builds_id_trigger

  def up
    return unless should_run?

    lock_tables(TABLE_NAME, :ci_builds)

    Gitlab::Database::PostgresPartitionedTable.each_partition(TABLE_NAME) do |partition|
      drop_trigger(partition.identifier, TRIGGER_NAME, if_exists: true)
    end

    create_trigger(TABLE_NAME, TRIGGER_NAME, FUNCTION_NAME, fires: 'BEFORE INSERT')
  end

  def down
    return unless should_run?

    drop_trigger(TABLE_NAME, TRIGGER_NAME, if_exists: true)
    return if trigger_exists?(:ci_builds, TRIGGER_NAME)

    Gitlab::Database::PostgresPartitionedTable.each_partition(TABLE_NAME) do |partition|
      create_trigger(partition.identifier, TRIGGER_NAME, FUNCTION_NAME, fires: 'BEFORE INSERT')
    end
  end

  private

  def should_run?
    can_execute_on?(:ci_builds)
  end
end
