# frozen_string_literal: true

class AddAbuseReportsForeignKeyToAbuseReportUserMentions < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :abuse_report_user_mentions, :abuse_reports, column: :abuse_report_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :abuse_report_user_mentions, column: :abuse_report_id
    end
  end
end
