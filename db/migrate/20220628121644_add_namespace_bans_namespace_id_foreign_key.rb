# frozen_string_literal: true

class AddNamespaceBansNamespaceIdForeignKey < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :namespace_bans, :namespaces, column: :namespace_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :namespace_bans, column: :namespace_id
    end
  end
end
