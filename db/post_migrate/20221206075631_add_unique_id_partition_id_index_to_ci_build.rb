# frozen_string_literal: true

class AddUniqueIdPartitionIdIndexToCiBuild < Gitlab::Database::Migration[2.1]
  TABLE_NAME = :ci_builds
  INDEX_NAME = :index_ci_builds_on_id_partition_id_unique
  COLUMNS = %i[id partition_id].freeze

  def up
    prepare_async_index(TABLE_NAME, COLUMNS, unique: true, name: INDEX_NAME)
  end

  def down
    unprepare_async_index(TABLE_NAME, COLUMNS, name: INDEX_NAME)
  end
end
