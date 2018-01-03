class AddForeignKeyToCiPipelineVariables < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key(:ci_pipeline_variables, :ci_pipelines, column: :pipeline_id)
  end

  def down
    remove_foreign_key(:ci_pipeline_variables, column: :pipeline_id)
  end
end
