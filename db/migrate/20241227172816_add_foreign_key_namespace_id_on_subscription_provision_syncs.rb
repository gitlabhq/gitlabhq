# frozen_string_literal: true

class AddForeignKeyNamespaceIdOnSubscriptionProvisionSyncs < Gitlab::Database::Migration[2.2]
  milestone '17.8'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :subscription_provision_syncs, :namespaces, column: :namespace_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :subscription_provision_syncs, column: :namespace_id
    end
  end
end
