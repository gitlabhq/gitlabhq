# frozen_string_literal: true

class ValidateAsyncFkCiDailyBuildGroupReportResultsParIdLastPipelineId < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  TABLE_NAME = :ci_daily_build_group_report_results
  FK_NAME = :fk_rails_ee072d13b3_p
  COLUMNS = [:partition_id, :last_pipeline_id]

  def up
    prepare_async_foreign_key_validation(TABLE_NAME, COLUMNS, name: FK_NAME)
  end

  def down
    unprepare_async_foreign_key_validation(TABLE_NAME, COLUMNS, name: FK_NAME)
  end
end
