# frozen_string_literal: true

class RemoveMachineIdFromBuildsMetadata < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!

  INDEX_NAME = 'p_ci_builds_metadata_on_runner_machine_id_idx'

  def up
    with_lock_retries do
      remove_column :p_ci_builds_metadata, :runner_machine_id, if_exists: true
    end
  end

  def down
    add_column :p_ci_builds_metadata, :runner_machine_id, :bigint, if_not_exists: true # rubocop: disable Migration/SchemaAdditionMethodsNoPost

    add_concurrent_partitioned_index :p_ci_builds_metadata, :runner_machine_id, name: INDEX_NAME,
      where: 'runner_machine_id IS NOT NULL'
  end
end
