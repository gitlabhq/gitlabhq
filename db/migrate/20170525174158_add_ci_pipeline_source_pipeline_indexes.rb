class AddCiPipelineSourcePipelineIndexes < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_sources_pipelines, :project_id
    add_concurrent_index :ci_sources_pipelines, :pipeline_id

    add_concurrent_index :ci_sources_pipelines, :source_project_id
    add_concurrent_index :ci_sources_pipelines, :source_job_id
    add_concurrent_index :ci_sources_pipelines, :source_pipeline_id
  end

  def down
    remove_concurrent_index :ci_sources_pipelines, :project_id if index_exists? :ci_sources_pipelines, :project_id
    remove_concurrent_index :ci_sources_pipelines, :pipeline_id if index_exists? :ci_sources_pipelines, :pipeline_id

    remove_concurrent_index :ci_sources_pipelines, :source_project_id if index_exists? :ci_sources_pipelines, :source_project_id
    remove_concurrent_index :ci_sources_pipelines, :source_job_id if index_exists? :ci_sources_pipelines, :source_job_id
    remove_concurrent_index :ci_sources_pipelines, :source_pipeline_id if index_exists? :ci_sources_pipelines, :source_pipeline_id
  end
end
