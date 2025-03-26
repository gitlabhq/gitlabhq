# frozen_string_literal: true

class AddSubscriptionSeatAssignmentOrganizationIdIndex < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  disable_ddl_transaction!

  INDEX_NAME = 'index_subscription_seat_assignments_on_organization_id'

  def up
    add_concurrent_index :subscription_seat_assignments, :organization_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :subscription_seat_assignments, INDEX_NAME
  end
end
