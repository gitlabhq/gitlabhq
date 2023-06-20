# frozen_string_literal: true

class AddForeignKeyConstraintsToAbuseReports < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    return if foreign_key_exists?(:abuse_reports, column: :resolved_by_id)

    add_concurrent_foreign_key :abuse_reports, :users,
      column: :resolved_by_id,
      null: true,
      on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :abuse_reports, column: :resolved_by_id
    end
  end
end
