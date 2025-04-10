# frozen_string_literal: true

class RemoveSeatAssignmentsNamespaceIdNotNull < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.11'

  def up
    change_column_null :subscription_seat_assignments, :namespace_id, true
  end

  def down
    change_column_null :subscription_seat_assignments, :namespace_id, false
  end
end
