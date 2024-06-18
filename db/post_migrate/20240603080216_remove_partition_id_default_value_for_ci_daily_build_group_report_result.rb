# frozen_string_literal: true

class RemovePartitionIdDefaultValueForCiDailyBuildGroupReportResult < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  TABLE_NAME = :ci_daily_build_group_report_results
  COLUM_NAME = :partition_id

  def change
    change_column_default(TABLE_NAME, COLUM_NAME, from: 100, to: nil)
  end
end
