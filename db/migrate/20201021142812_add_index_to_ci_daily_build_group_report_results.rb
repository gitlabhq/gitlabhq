# frozen_string_literal: true

class AddIndexToCiDailyBuildGroupReportResults < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_ci_daily_build_group_report_results_on_project_and_date'

  disable_ddl_transaction!

  def up
    add_concurrent_index(
      :ci_daily_build_group_report_results,
      [:project_id, :date],
      order: { date: :desc },
      where: "default_branch = TRUE AND (data -> 'coverage') IS NOT NULL",
      name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_index_by_name(:ci_daily_build_group_report_results, INDEX_NAME)
  end
end
