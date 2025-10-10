# frozen_string_literal: true

class RemoveAbuseReportAssigneesAbuseReportIdFk < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key :abuse_report_assignees, :abuse_reports, column: :abuse_report_id
    end
  end

  def down
    add_concurrent_foreign_key :abuse_report_assignees, :abuse_reports, column: :abuse_report_id,
      name: 'fk_rails_fd5f22166b'
  end
end
