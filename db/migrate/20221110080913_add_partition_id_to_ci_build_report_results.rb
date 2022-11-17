# frozen_string_literal: true

class AddPartitionIdToCiBuildReportResults < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def change
    add_column :ci_build_report_results, :partition_id, :bigint, default: 100, null: false
  end
end
