# frozen_string_literal: true

class RemoveExecutionConfigIdFromPCiBuilds < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '19.3'

  INDEX_NAME = 'index_p_ci_builds_on_execution_config_id'

  def up
    with_lock_retries do
      remove_column :p_ci_builds, :execution_config_id, if_exists: true
    end
  end

  def down
    with_lock_retries do
      add_column :p_ci_builds, :execution_config_id, :bigint, if_not_exists: true
    end

    add_concurrent_partitioned_index(
      :p_ci_builds,
      :execution_config_id,
      name: INDEX_NAME,
      where: 'execution_config_id IS NOT NULL'
    )
  end
end
