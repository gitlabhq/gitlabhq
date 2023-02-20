# frozen_string_literal: true

class AddPartitionIndexToBuildsMetadata < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!

  INDEX_NAME = 'p_ci_builds_metadata_on_runner_machine_id_idx'

  def up
    add_concurrent_partitioned_index :p_ci_builds_metadata, :runner_machine_id, name: INDEX_NAME,
      where: 'runner_machine_id IS NOT NULL'
  end

  def down
    remove_concurrent_partitioned_index_by_name :p_ci_builds_metadata, INDEX_NAME
  end
end
