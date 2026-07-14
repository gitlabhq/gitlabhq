# frozen_string_literal: true

class AddAiConfigTimestampsToCiProjectMetrics < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :ci_project_metrics, :ci_config_first_generated_at, :datetime_with_timezone,
        null: true, if_not_exists: true
      add_column :ci_project_metrics, :first_ai_pipeline_results_viewed_at, :datetime_with_timezone,
        null: true, if_not_exists: true
    end
  end

  def down
    with_lock_retries do
      remove_column :ci_project_metrics, :ci_config_first_generated_at, if_exists: true
      remove_column :ci_project_metrics, :first_ai_pipeline_results_viewed_at, if_exists: true
    end
  end
end
