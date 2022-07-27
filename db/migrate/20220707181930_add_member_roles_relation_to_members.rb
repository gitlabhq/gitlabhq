# frozen_string_literal: true

class AddMemberRolesRelationToMembers < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!
  INDEX_NAME = 'index_members_on_member_role_id'

  def up
    add_concurrent_index :members, :member_role_id, name: INDEX_NAME
    add_concurrent_foreign_key :members, :member_roles, column: :member_role_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :members, column: :member_role_id
    end

    remove_concurrent_index_by_name :members, INDEX_NAME
  end
end
