# frozen_string_literal: true

class DropIdPartitionIdIndexFromPCiBuildMetadata < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!

  TABLE_NAME = :p_ci_builds_metadata
  INDEX_NAME = :p_ci_builds_metadata_id_partition_id_idx

  def up
    remove_concurrent_partitioned_index_by_name(TABLE_NAME, INDEX_NAME)
  end

  def down
    add_concurrent_partitioned_index(TABLE_NAME, %i[id partition_id], unique: true, name: INDEX_NAME)
  end
end
