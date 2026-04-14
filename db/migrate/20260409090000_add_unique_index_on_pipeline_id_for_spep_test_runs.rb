# frozen_string_literal: true

class AddUniqueIndexOnPipelineIdForSpepTestRuns < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.11'

  TABLE_NAME = :security_scheduled_pipeline_execution_policy_test_runs
  OLD_INDEX_NAME = 'idx_spep_test_runs_pipeline_id'
  UNIQUE_INDEX_NAME = 'idx_spep_test_runs_pipeline_id_unique'

  def up
    add_concurrent_index TABLE_NAME, :pipeline_id,
      unique: true,
      where: 'pipeline_id IS NOT NULL',
      name: UNIQUE_INDEX_NAME

    remove_concurrent_index_by_name TABLE_NAME, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index TABLE_NAME, :pipeline_id, name: OLD_INDEX_NAME

    remove_concurrent_index_by_name TABLE_NAME, UNIQUE_INDEX_NAME
  end
end
