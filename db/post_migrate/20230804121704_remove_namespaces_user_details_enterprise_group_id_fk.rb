# frozen_string_literal: true

class RemoveNamespacesUserDetailsEnterpriseGroupIdFk < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    return unless foreign_key_exists?(:user_details, :namespaces, name: "fk_c53c794142")

    with_lock_retries do
      remove_foreign_key_if_exists(:user_details, :namespaces,
        name: "fk_c53c794142", reverse_lock_order: true)
    end
  end

  def down
    add_concurrent_foreign_key(:user_details, :namespaces,
      name: "fk_c53c794142", column: :enterprise_group_id,
      target_column: :id, on_delete: :nullify)
  end
end
