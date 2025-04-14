# frozen_string_literal: true

class ReplaceSubscriptionSeatAssignmentsNamespaceIdIdx < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.11'

  OLD_IDX_NAME = 'uniq_idx_subscription_seat_assignments_on_namespace_and_user'
  NEW_IDX_NAME = 'uniq_idx_subscription_seat_assignments_on_namespace_id_and_user'

  def up
    remove_concurrent_index :subscription_seat_assignments, [:namespace_id, :user_id], name: OLD_IDX_NAME

    add_concurrent_index :subscription_seat_assignments, [:namespace_id, :user_id],
      name: NEW_IDX_NAME, unique: true, where: "namespace_id IS NOT NULL"
  end

  def down
    remove_concurrent_index :subscription_seat_assignments, [:namespace_id, :user_id], name: NEW_IDX_NAME
    add_concurrent_index :subscription_seat_assignments, [:namespace_id, :user_id], name: OLD_IDX_NAME, unique: true
  end
end
