# frozen_string_literal: true

class AddSeatTypeToSubscriptionSeatAssignments < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    add_column :subscription_seat_assignments, :seat_type, :integer, limit: 2
  end
end
