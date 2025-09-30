# frozen_string_literal: true

class AddForeignKeyAbuseReporToReporterId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.5'

  def up
    add_concurrent_foreign_key :abuse_reports, :users, column: :reporter_id
  end

  def down
    with_lock_retries do
      remove_foreign_key :abuse_reports, :users, column: :reporter_id
    end
  end
end
