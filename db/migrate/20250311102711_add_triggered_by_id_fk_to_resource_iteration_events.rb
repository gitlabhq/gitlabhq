# frozen_string_literal: true

class AddTriggeredByIdFkToResourceIterationEvents < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.11'

  def up
    add_concurrent_foreign_key :resource_iteration_events, :issues, column: :triggered_by_id,
      on_delete: :nullify, validate: false
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :resource_iteration_events, column: :triggered_by_id
    end
  end
end
