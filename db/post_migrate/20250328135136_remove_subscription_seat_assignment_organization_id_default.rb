# frozen_string_literal: true

class RemoveSubscriptionSeatAssignmentOrganizationIdDefault < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    change_column_default(:subscription_seat_assignments, :organization_id, from: 1, to: nil)
  end
end
