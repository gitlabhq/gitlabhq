# frozen_string_literal: true

class AddUserIdAndSourceIdAndSourceTypeAndMemberRoleIdIndexToMembers < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'idx_members_on_user_and_source_and_source_type_and_member_role'

  def up
    add_concurrent_index :members, [:user_id, :source_id, :source_type, :member_role_id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :members, name: INDEX_NAME
  end
end
