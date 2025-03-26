# frozen_string_literal: true

class AddOrganizationIdToSubscriptionSeatAssignments < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  DEFAULT_ORGANIZATION_ID = 1
  enable_lock_retries!

  def change
    add_column :subscription_seat_assignments, :organization_id, :bigint, default: DEFAULT_ORGANIZATION_ID, null: false
  end
end
