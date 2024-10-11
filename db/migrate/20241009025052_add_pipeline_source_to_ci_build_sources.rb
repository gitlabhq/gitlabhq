# frozen_string_literal: true

class AddPipelineSourceToCiBuildSources < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!

  milestone '17.5'

  INDEX_NAME = 'index_p_ci_build_sources_on_pipeline_source'

  def up
    add_column :p_ci_build_sources, :pipeline_source, :smallint

    add_concurrent_partitioned_index :p_ci_build_sources, :pipeline_source, name: INDEX_NAME
  end

  def down
    remove_concurrent_partitioned_index_by_name :p_ci_build_sources, INDEX_NAME

    remove_column :p_ci_build_sources, :pipeline_source
  end
end
