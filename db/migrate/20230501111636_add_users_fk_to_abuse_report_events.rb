# frozen_string_literal: true

class AddUsersFkToAbuseReportEvents < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :abuse_report_events,
      :users,
      column: :user_id,
      on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :abuse_report_events, column: :user_id
    end
  end
end
