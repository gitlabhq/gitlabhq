# frozen_string_literal: true

class AddMemberNamespaceIndex < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!
  INDEX_NAME = 'index_members_on_member_namespace_id'

  def up
    add_concurrent_index :members, :member_namespace_id, unique: false, name: INDEX_NAME
    add_concurrent_foreign_key :members, :namespaces, column: :member_namespace_id, on_delete: :nullify, reverse_lock_order: true
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :members, column: :member_namespace_id
    end

    remove_concurrent_index_by_name :members, INDEX_NAME
  end
end
