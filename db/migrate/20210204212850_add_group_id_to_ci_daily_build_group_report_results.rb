# frozen_string_literal: true

class AddGroupIdToCiDailyBuildGroupReportResults < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column(:ci_daily_build_group_report_results, :group_id, :bigint)
  end
end
