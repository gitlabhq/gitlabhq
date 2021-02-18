# frozen_string_literal: true

class AddIndexGroupIdToCiDailyBuildGroupReportResults < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_ci_daily_build_group_report_results_on_group_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index(:ci_daily_build_group_report_results, :group_id, name: INDEX_NAME)
    add_concurrent_foreign_key(:ci_daily_build_group_report_results, :namespaces, column: :group_id)
  end

  def down
    remove_foreign_key_if_exists(:ci_daily_build_group_report_results, column: :group_id)
    remove_concurrent_index_by_name(:ci_daily_build_group_report_results, INDEX_NAME)
  end
end
