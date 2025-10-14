# frozen_string_literal: true

class AddOrganizationIdToAbuseReportAssignees < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  def change
    add_column :abuse_report_assignees, :organization_id, :bigint, null: false, default: 1
  end
end
