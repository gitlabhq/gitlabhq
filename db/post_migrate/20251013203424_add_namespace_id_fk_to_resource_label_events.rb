# frozen_string_literal: true

class AddNamespaceIdFkToResourceLabelEvents < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.6'

  def up
    add_concurrent_foreign_key :resource_label_events, :namespaces, column: :namespace_id, reverse_lock_order: true
  end

  def down
    with_lock_retries do
      remove_foreign_key :resource_label_events, column: :namespace_id
    end
  end
end
