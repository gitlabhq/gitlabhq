# frozen_string_literal: true

class AddForeignKeyToUserDetailOnBotNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key(:user_details, :namespaces, column: :bot_namespace_id, on_delete: :nullify)
  end

  def down
    with_lock_retries do
      remove_foreign_key(:user_details, column: :bot_namespace_id)
    end
  end
end
