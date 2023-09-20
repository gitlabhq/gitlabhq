# frozen_string_literal: true

class RemoveNamespacesRoutesNamespaceIdFk < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  FOREIGN_KEY_NAME = "fk_bb2e5b8968"

  def up
    return unless foreign_key_exists?(:routes, :namespaces, name: FOREIGN_KEY_NAME)

    with_lock_retries do
      remove_foreign_key_if_exists(:routes, :namespaces,
        name: FOREIGN_KEY_NAME, reverse_lock_order: true)
    end
  end

  def down
    add_concurrent_foreign_key(:routes, :namespaces,
      name: FOREIGN_KEY_NAME, column: :namespace_id,
      target_column: :id, on_delete: :cascade)
  end
end
