# frozen_string_literal: true

class AddDefaultBranchToDailyBuildGroupReportResult < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :ci_daily_build_group_report_results, :default_branch, :boolean, default: false, null: false
  end
end
