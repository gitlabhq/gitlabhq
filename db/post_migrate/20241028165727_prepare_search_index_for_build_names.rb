# frozen_string_literal: true

class PrepareSearchIndexForBuildNames < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '17.6'
  disable_ddl_transaction!

  TABLE_NAME = :p_ci_build_names
  INDEX_NAME = :index_p_ci_build_names_on_search_columns
  COLUMNS = %i[project_id name build_id partition_id]

  def up
    prepare_partitioned_async_index(TABLE_NAME, COLUMNS, name: INDEX_NAME)
  end

  def down
    unprepare_partitioned_async_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
