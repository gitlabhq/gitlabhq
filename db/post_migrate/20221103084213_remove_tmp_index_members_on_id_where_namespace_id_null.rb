# frozen_string_literal: true

class RemoveTmpIndexMembersOnIdWhereNamespaceIdNull < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'tmp_index_members_on_id_where_namespace_id_null'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :members, INDEX_NAME
  end

  def down
    add_concurrent_index :members, :id, name: INDEX_NAME, where: 'member_namespace_id IS NULL'
  end
end
