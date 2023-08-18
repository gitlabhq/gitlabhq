# frozen_string_literal: true

class AddTempIndexForProjectStatisticsPipelineArtifactsSizeMigration < Gitlab::Database::Migration[2.1]
  INDEX_PROJECT_STATSISTICS_PIPELINE_ARTIFACTS_SIZE = 'tmp_index_project_statistics_pipeline_artifacts_size'

  disable_ddl_transaction!

  def up
    # Temporary index is to be used to trigger a refresh of project_statistics with
    # pipeline_artifacts_size != 0
    add_concurrent_index :project_statistics, [:project_id],
      name: INDEX_PROJECT_STATSISTICS_PIPELINE_ARTIFACTS_SIZE,
      where: "pipeline_artifacts_size != 0"
  end

  def down
    remove_concurrent_index_by_name :project_statistics, INDEX_PROJECT_STATSISTICS_PIPELINE_ARTIFACTS_SIZE
  end
end
