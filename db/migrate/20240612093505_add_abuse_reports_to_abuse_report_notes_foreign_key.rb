# frozen_string_literal: true

class AddAbuseReportsToAbuseReportNotesForeignKey < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.2'

  def up
    add_concurrent_foreign_key :abuse_report_notes, :abuse_reports, column: :abuse_report_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :abuse_report_notes, column: :abuse_report_id
    end
  end
end
