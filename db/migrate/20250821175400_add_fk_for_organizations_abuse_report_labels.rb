# frozen_string_literal: true

class AddFkForOrganizationsAbuseReportLabels < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.4'

  def up
    add_concurrent_foreign_key :abuse_report_labels, :organizations, column: :organization_id, validate: true
  end

  def down
    with_lock_retries do
      remove_foreign_key :abuse_report_labels, :organizations, column: :organization_id
    end
  end
end
