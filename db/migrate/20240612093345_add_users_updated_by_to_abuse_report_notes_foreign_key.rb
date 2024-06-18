# frozen_string_literal: true

class AddUsersUpdatedByToAbuseReportNotesForeignKey < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.2'

  def up
    add_concurrent_foreign_key :abuse_report_notes, :users, column: :updated_by_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :abuse_report_notes, column: :updated_by_id
    end
  end
end
