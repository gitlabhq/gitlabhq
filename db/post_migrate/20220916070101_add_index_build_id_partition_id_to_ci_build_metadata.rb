# frozen_string_literal: true

class AddIndexBuildIdPartitionIdToCiBuildMetadata < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  TABLE_NAME = :ci_builds_metadata
  INDEX_NAME = :index_ci_builds_metadata_on_build_id_partition_id_unique

  def up
    add_concurrent_index(TABLE_NAME, %i[build_id partition_id], unique: true, name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
