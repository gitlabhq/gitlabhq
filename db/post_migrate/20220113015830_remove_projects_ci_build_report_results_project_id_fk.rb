# frozen_string_literal: true

class RemoveProjectsCiBuildReportResultsProjectIdFk < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:ci_build_report_results, :projects, name: "fk_rails_056d298d48")
    end
  end

  def down
    add_concurrent_foreign_key(:ci_build_report_results, :projects, name: "fk_rails_056d298d48", column: :project_id, target_column: :id, on_delete: "cascade")
  end
end
