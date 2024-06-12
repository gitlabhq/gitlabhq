# frozen_string_literal: true

class AddOrganizationIdToUpcomingReconciliations < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  DEFAULT_ORGANIZATION_ID = 1

  def change
    add_column :upcoming_reconciliations, :organization_id, :bigint, default: DEFAULT_ORGANIZATION_ID, null: false
  end
end
