# frozen_string_literal: true

class AddUniqueIdPartitionIdIndexToCiBuildMetadata < Gitlab::Database::Migration[2.0]
  TABLE_NAME = :ci_builds_metadata
  INDEX_NAME = :index_ci_builds_metadata_on_id_partition_id_unique

  def up
    prepare_async_index(TABLE_NAME, %i[id partition_id], unique: true, name: INDEX_NAME)
  end

  def down
    unprepare_async_index(:ci_builds_metadata, %i[id partition_id], name: INDEX_NAME)
  end
end
