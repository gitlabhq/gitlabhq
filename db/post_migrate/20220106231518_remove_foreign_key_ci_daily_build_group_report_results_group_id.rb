# frozen_string_literal: true

class RemoveForeignKeyCiDailyBuildGroupReportResultsGroupId < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'fk_fd1858fefd'

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:ci_daily_build_group_report_results, :namespaces, name: CONSTRAINT_NAME)
    end
  end

  def down
    add_concurrent_foreign_key :ci_daily_build_group_report_results, :namespaces, column: :group_id, on_delete: :cascade, name: CONSTRAINT_NAME
  end
end
