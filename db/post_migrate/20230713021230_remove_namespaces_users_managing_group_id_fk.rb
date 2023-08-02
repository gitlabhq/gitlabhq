# frozen_string_literal: true

class RemoveNamespacesUsersManagingGroupIdFk < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    return unless foreign_key_exists?(:users, :namespaces, name: "fk_a4b8fefe3e")

    with_lock_retries do
      remove_foreign_key_if_exists(:users, :namespaces,
        name: "fk_a4b8fefe3e", reverse_lock_order: true)
    end
  end

  def down
    add_concurrent_foreign_key(:users, :namespaces,
      name: "fk_a4b8fefe3e", column: :managing_group_id,
      target_column: :id, on_delete: :nullify)
  end
end
