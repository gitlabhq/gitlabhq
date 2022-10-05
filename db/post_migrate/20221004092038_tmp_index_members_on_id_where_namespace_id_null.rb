# frozen_string_literal: true

class TmpIndexMembersOnIdWhereNamespaceIdNull < Gitlab::Database::Migration[2.0]
  TMP_INDEX = 'tmp_index_members_on_id_where_namespace_id_null'

  disable_ddl_transaction!

  def up
    add_concurrent_index :members, :id,
    name: TMP_INDEX,
    where: 'member_namespace_id IS NULL'
  end

  def down
    remove_concurrent_index_by_name :members, name: TMP_INDEX
  end
end
