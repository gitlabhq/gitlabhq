# frozen_string_literal: true

class RemoveForeignKeyOnProvisionSyncs < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists :subscription_provision_syncs, column: :namespace_id
    end
  end

  def down
    add_concurrent_foreign_key :subscription_provision_syncs, :namespaces, column: :namespace_id, on_delete: :cascade
  end
end
