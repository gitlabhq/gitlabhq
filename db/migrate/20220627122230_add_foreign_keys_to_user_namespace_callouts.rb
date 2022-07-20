# frozen_string_literal: true

class AddForeignKeysToUserNamespaceCallouts < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :user_namespace_callouts, :users,
      column: :user_id,
      on_delete: :cascade

    add_concurrent_foreign_key :user_namespace_callouts, :namespaces,
      column: :namespace_id,
      on_delete: :cascade

    add_concurrent_index :user_namespace_callouts, [:user_id, :feature_name, :namespace_id],
      unique: true,
      name: 'index_ns_user_callouts_feature'
  end

  def down
    remove_concurrent_index_by_name :user_namespace_callouts, 'index_ns_user_callouts_feature'

    with_lock_retries do
      remove_foreign_key :user_namespace_callouts, column: :user_id
      remove_foreign_key :user_namespace_callouts, column: :namespace_id
    end
  end
end
