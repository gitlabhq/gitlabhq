# frozen_string_literal: true

class AddOrganizationIdToAbuseReports < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  def change
    add_column :abuse_reports, :organization_id, :bigint
  end
end
