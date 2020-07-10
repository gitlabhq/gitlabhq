# frozen_string_literal: true

class RemoveFKeysFromCiDailyReportResultsTable < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists :ci_daily_report_results, :projects
      remove_foreign_key_if_exists :ci_daily_report_results, :ci_pipelines
    end
  end

  def down
    add_concurrent_foreign_key :ci_daily_report_results, :projects, column: :project_id, on_delete: :cascade
    add_concurrent_foreign_key :ci_daily_report_results, :ci_pipelines, column: :last_pipeline_id, on_delete: :cascade
  end
end
