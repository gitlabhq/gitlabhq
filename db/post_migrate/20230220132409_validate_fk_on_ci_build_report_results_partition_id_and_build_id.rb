# frozen_string_literal: true

class ValidateFkOnCiBuildReportResultsPartitionIdAndBuildId < Gitlab::Database::Migration[2.1]
  TABLE_NAME = :ci_build_report_results
  FK_NAME = :fk_rails_16cb1ff064_p
  COLUMNS = [:partition_id, :build_id]

  def up
    validate_foreign_key(TABLE_NAME, COLUMNS, name: FK_NAME)
  end

  def down
    # no-op
  end
end
