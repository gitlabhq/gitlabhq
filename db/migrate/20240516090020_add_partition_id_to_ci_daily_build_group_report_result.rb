# frozen_string_literal: true

class AddPartitionIdToCiDailyBuildGroupReportResult < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column(:ci_daily_build_group_report_results, :partition_id, :bigint, default: 100, null: false)
  end
end
