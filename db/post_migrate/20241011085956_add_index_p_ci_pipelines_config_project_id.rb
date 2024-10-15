# frozen_string_literal: true

class AddIndexPCiPipelinesConfigProjectId < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '17.6'
  disable_ddl_transaction!

  TABLE_NAME = :p_ci_pipelines_config
  INDEX_NAME = :index_p_ci_pipelines_config_on_project_id

  def up
    add_concurrent_partitioned_index(TABLE_NAME, :project_id, name: INDEX_NAME)
  end

  def down
    remove_concurrent_partitioned_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
