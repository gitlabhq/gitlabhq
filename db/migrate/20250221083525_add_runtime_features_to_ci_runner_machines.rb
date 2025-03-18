# frozen_string_literal: true

class AddRuntimeFeaturesToCiRunnerMachines < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  milestone '17.10'
  disable_ddl_transaction!

  TABLE_NAME = 'ci_runner_machines'
  PARTITIONED_TABLE_NAME = 'ci_runner_machines_687967fa8a'

  def up
    with_lock_retries do
      add_column PARTITIONED_TABLE_NAME, :runtime_features,
        :jsonb, default: {}, null: false, if_not_exists: true
    end

    with_lock_retries do
      add_column TABLE_NAME, :runtime_features,
        :jsonb, default: {}, null: false, if_not_exists: true
    end

    with_lock_retries do
      current_primary_key = Array.wrap(connection.primary_key(TABLE_NAME))

      drop_sync_trigger(TABLE_NAME) # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- false positive
      create_trigger_to_sync_tables(TABLE_NAME, PARTITIONED_TABLE_NAME, current_primary_key)
    end
  end

  def down
    with_lock_retries do
      remove_column TABLE_NAME, :runtime_features, if_exists: true
    end

    with_lock_retries do
      remove_column PARTITIONED_TABLE_NAME, :runtime_features, if_exists: true
    end

    with_lock_retries do
      current_primary_key = Array.wrap(connection.primary_key(TABLE_NAME))

      drop_sync_trigger(TABLE_NAME) # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- false positive
      create_trigger_to_sync_tables(TABLE_NAME, PARTITIONED_TABLE_NAME, current_primary_key)
    end
  end
end
