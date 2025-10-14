# frozen_string_literal: true

class AddOrganizationIdToSpamLogs < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  def change
    add_column :spam_logs, :organization_id, :bigint
  end
end
