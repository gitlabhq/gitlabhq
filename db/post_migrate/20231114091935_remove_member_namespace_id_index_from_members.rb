# frozen_string_literal: true

class RemoveMemberNamespaceIdIndexFromMembers < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.7'

  INDEX_NAME = 'index_members_on_member_namespace_id'

  def up
    remove_concurrent_index_by_name :members, INDEX_NAME
  end

  def down
    add_concurrent_index :members, :member_namespace_id, name: INDEX_NAME
  end
end
