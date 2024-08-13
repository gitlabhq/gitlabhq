# frozen_string_literal: true

class PartitionedFkToCiPipelinesFromCiDailyBuildGroupReportResults < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  SOURCE_TABLE_NAME = :ci_daily_build_group_report_results
  COLUMN = :last_pipeline_id
  PARTITION_COLUMN = :partition_id
  FK_NAME = :fk_rails_ee072d13b3_p

  def up
    validate_foreign_key(
      SOURCE_TABLE_NAME, [PARTITION_COLUMN, COLUMN],
      name: FK_NAME
    )
  end

  def down
    # no-op
  end
end
