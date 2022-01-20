# frozen_string_literal: true

class RemoveProjectsCiDailyBuildGroupReportResultsProjectIdFk < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      execute('LOCK projects, ci_daily_build_group_report_results IN ACCESS EXCLUSIVE MODE')
      remove_foreign_key_if_exists(:ci_daily_build_group_report_results, :projects, name: "fk_rails_0667f7608c")
    end
  end

  def down
    add_concurrent_foreign_key(:ci_daily_build_group_report_results, :projects, name: "fk_rails_0667f7608c", column: :project_id, target_column: :id, on_delete: "cascade")
  end
end
