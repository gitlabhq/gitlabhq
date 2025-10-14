# frozen_string_literal: true

class RemoveAbuseReportAssigneesOrganizationIdFk < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key :abuse_report_assignees, :organizations, column: :organization_id
    end
  end

  def down
    add_concurrent_foreign_key :abuse_report_assignees, :organizations, column: :organization_id, name: 'fk_5c33be07d3'
  end
end
