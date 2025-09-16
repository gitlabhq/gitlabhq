# frozen_string_literal: true

class AddOrganizationIdToAbuseReportEvents < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  def change
    add_column :abuse_report_events, :organization_id, :bigint
  end
end
