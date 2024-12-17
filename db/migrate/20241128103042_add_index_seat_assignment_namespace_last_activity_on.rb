# frozen_string_literal: true

class AddIndexSeatAssignmentNamespaceLastActivityOn < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  disable_ddl_transaction!

  TABLE = :subscription_seat_assignments
  INDEX = 'idx_subscription_seat_assignments_namespace_last_activity_on'

  def up
    add_concurrent_index(
      TABLE,
      %i[namespace_id last_activity_on created_at],
      name: INDEX
    )
  end

  def down
    remove_concurrent_index_by_name TABLE, INDEX
  end
end
