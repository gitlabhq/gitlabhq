# frozen_string_literal: true

class AddStaleIndexToSpepTestRuns < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.3'

  INDEX_NAME = 'idx_spep_test_runs_on_state_and_created_at_for_stale'

  def up
    # Partial index for cleanup worker that queries stale pending (state=3) and running (state=0) records
    add_concurrent_index(
      :security_scheduled_pipeline_execution_policy_test_runs,
      [:state, :created_at],
      name: INDEX_NAME,
      where: 'state IN (0, 3)'
    )
  end

  def down
    remove_concurrent_index_by_name(
      :security_scheduled_pipeline_execution_policy_test_runs,
      INDEX_NAME
    )
  end
end
