class AddCiPipelineSourcePipelineForeignKey < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :ci_sources_pipelines, :projects, column: :project_id
    add_concurrent_foreign_key :ci_sources_pipelines, :ci_pipelines, column: :pipeline_id

    add_concurrent_foreign_key :ci_sources_pipelines, :projects, column: :source_project_id
    add_concurrent_foreign_key :ci_sources_pipelines, :ci_builds, column: :source_job_id
    add_concurrent_foreign_key :ci_sources_pipelines, :ci_pipelines, column: :source_pipeline_id
  end

  def down
    remove_foreign_key :ci_sources_pipelines, column: :project_id
    remove_foreign_key :ci_sources_pipelines, column: :pipeline_id

    remove_foreign_key :ci_sources_pipelines, column: :source_project_id
    remove_foreign_key :ci_sources_pipelines, column: :source_job_id
    remove_foreign_key :ci_sources_pipelines, column: :source_pipeline_id
  end
end
