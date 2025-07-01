# frozen_string_literal: true

class AddResourceStateEventsNamespaceIdForeignKey < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.2'

  def up
    add_concurrent_foreign_key :resource_state_events,
      :namespaces,
      column: :namespace_id,
      reverse_lock_order: true,
      validate: false
  end

  def down
    with_lock_retries do
      remove_foreign_key :resource_state_events, column: :namespace_id
    end
  end
end
