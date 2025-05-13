# frozen_string_literal: true

class AddNamespaceForeignKeyToImportPlaceholderUserDetails < Gitlab::Database::Migration[2.3]
  milestone '18.0'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :import_placeholder_user_details, :namespaces, column: :namespace_id,
      on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key :import_placeholder_user_details, column: :namespace_id
    end
  end
end
