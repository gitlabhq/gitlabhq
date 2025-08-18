# frozen_string_literal: true

class AddFkForOrganizationsAbuseReports < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.4'

  def up
    add_concurrent_foreign_key :abuse_reports, :organizations, column: :organization_id
  end

  def down
    with_lock_retries do
      remove_foreign_key :abuse_reports, :organizations, column: :organization_id
    end
  end
end
