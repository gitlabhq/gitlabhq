# frozen_string_literal: true

class AddOrganizationIdToAbuseReportUserMentions < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  def change
    add_column :abuse_report_user_mentions, :organization_id, :bigint
  end
end
