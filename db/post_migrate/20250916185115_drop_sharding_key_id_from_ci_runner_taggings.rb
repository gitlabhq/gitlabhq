# frozen_string_literal: true

class DropShardingKeyIdFromCiRunnerTaggings < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!

  milestone '18.5'

  TABLE_NAME = :ci_runner_taggings
  COLUMN_NAME = :sharding_key_id

  def up
    with_lock_retries do
      remove_column TABLE_NAME, COLUMN_NAME, if_exists: true
    end
  end

  def down
    with_lock_retries do
      add_column TABLE_NAME, COLUMN_NAME, :bigint, null: true, if_not_exists: true
    end

    {
      ci_runner_taggings_instance_type: 'index_ci_runner_taggings_instance_type_on_sharding_key_id',
      ci_runner_taggings_group_type: 'index_ci_runner_taggings_group_type_on_sharding_key_id',
      ci_runner_taggings_project_type: 'index_ci_runner_taggings_project_type_on_sharding_key_id'
    }.each do |table_name, index_name|
      add_concurrent_index(table_name, COLUMN_NAME, name: index_name, allow_partition: true)
    end

    # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- existing logic from add_concurrent_partitioned_index
    with_lock_retries do
      add_index( # rubocop:disable Migration/AddIndex -- no need for add_concurrent_index as this is just the routing table
        TABLE_NAME,
        COLUMN_NAME,
        name: 'index_ci_runner_taggings_on_sharding_key_id'
      )
    end
    # rubocop:enable Migration/WithLockRetriesDisallowedMethod
  end
end
