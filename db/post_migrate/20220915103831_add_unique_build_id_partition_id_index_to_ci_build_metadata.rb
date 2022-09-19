# frozen_string_literal: true

class AddUniqueBuildIdPartitionIdIndexToCiBuildMetadata < Gitlab::Database::Migration[2.0]
  TABLE_NAME = :ci_builds_metadata
  INDEX_NAME = :index_ci_builds_metadata_on_build_id_partition_id_unique

  def up
    prepare_async_index(TABLE_NAME, %i[build_id partition_id], unique: true, name: INDEX_NAME)
  end

  def down
    unprepare_async_index(:ci_builds_metadata, %i[build_id partition_id], name: INDEX_NAME)
  end
end
