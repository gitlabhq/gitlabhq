# frozen_string_literal: true

class AddForeignKeyToBuildIdOnBuildReportResults < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_foreign_key :ci_build_report_results, :ci_builds, column: :build_id, on_delete: :cascade # rubocop:disable Migration/AddConcurrentForeignKey
    end
  end

  def down
    with_lock_retries do
      remove_foreign_key :ci_build_report_results, column: :build_id
    end
  end
end
