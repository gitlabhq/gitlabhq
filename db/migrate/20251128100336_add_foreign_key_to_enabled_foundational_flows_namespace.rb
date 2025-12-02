# frozen_string_literal: true

class AddForeignKeyToEnabledFoundationalFlowsNamespace < Gitlab::Database::Migration[2.3]
  milestone '18.7'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :enabled_foundational_flows, :namespaces, column: :namespace_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :enabled_foundational_flows, column: :namespace_id
    end
  end
end
