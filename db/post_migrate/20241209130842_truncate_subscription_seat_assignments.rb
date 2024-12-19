# frozen_string_literal: true

class TruncateSubscriptionSeatAssignments < Gitlab::Database::Migration[2.2]
  milestone '17.8'
  disable_ddl_transaction!

  def up
    truncate_tables!('subscription_seat_assignments')
  end

  def down
    # no-op
  end
end
