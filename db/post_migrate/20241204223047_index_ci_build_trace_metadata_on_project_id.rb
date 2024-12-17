# frozen_string_literal: true

class IndexCiBuildTraceMetadataOnProjectId < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '17.7'

  TABLE_NAME = :p_ci_build_trace_metadata
  INDEX_NAME = :index_p_ci_build_trace_metadata_on_project_id

  def up
    add_concurrent_partitioned_index(TABLE_NAME, :project_id, name: INDEX_NAME)
  end

  def down
    remove_concurrent_partitioned_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
