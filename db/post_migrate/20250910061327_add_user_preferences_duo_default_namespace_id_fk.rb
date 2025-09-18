# frozen_string_literal: true

class AddUserPreferencesDuoDefaultNamespaceIdFk < Gitlab::Database::Migration[2.3]
  milestone '18.5'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :user_preferences, :namespaces, column: :duo_default_namespace_id, on_delete: :nullify
  end

  def down
    remove_foreign_key_if_exists :user_preferences, column: :duo_default_namespace_id
  end
end
