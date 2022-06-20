# frozen_string_literal: true

class DropCiBuildReportResultsBuildIdSequence < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def up
    drop_sequence(:ci_build_report_results, :build_id, :ci_build_report_results_build_id_seq)
  end

  def down
    add_sequence(:ci_build_report_results, :build_id, :ci_build_report_results_build_id_seq, 1)
  end
end
