class CreatePipelineSourcePipeline < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :ci_sources_pipelines, force: :cascade do |t|
      t.integer :project_id
      t.integer :pipeline_id

      t.integer :source_project_id
      t.integer :source_job_id
      t.integer :source_pipeline_id
    end
  end
end
