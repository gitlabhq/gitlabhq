# frozen_string_literal: true

class AddNotNullConstraintToResourceIterationEventsIteration < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.11'

  def up
    add_not_null_constraint :resource_iteration_events, :iteration_id
  end

  def down
    remove_not_null_constraint :resource_iteration_events, :iteration_id
  end
end
