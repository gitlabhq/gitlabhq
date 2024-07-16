# frozen_string_literal: true

class AddUsersAuthorToAbuseReportNotesForeignKey < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.2'

  def up
    add_concurrent_foreign_key :abuse_report_notes, :users, column: :author_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :abuse_report_notes, column: :author_id
    end
  end
end
