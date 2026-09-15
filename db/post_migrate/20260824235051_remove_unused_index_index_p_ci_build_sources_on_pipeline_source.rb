# frozen_string_literal: true

class RemoveUnusedIndexIndexPCiBuildSourcesOnPipelineSource < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!

  TABLE_NAME = :p_ci_build_sources
  INDEX_NAME = :index_p_ci_build_sources_on_pipeline_source
  COLUMN_NAMES = [:pipeline_source]

  def up
    remove_concurrent_partitioned_index_by_name(TABLE_NAME, INDEX_NAME)
  end

  def down
    add_concurrent_partitioned_index(TABLE_NAME, COLUMN_NAMES, name: INDEX_NAME)
  end
end
