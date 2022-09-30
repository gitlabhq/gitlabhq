# frozen_string_literal: true

class TmpIdxNullMemberNamespaceId < Gitlab::Database::Migration[2.0]
  TMP_INDEX_FOR_NULL_MEMBER_NAMESPACE_ID = 'tmp_index_for_null_member_namespace_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :members, :member_namespace_id,
    name: TMP_INDEX_FOR_NULL_MEMBER_NAMESPACE_ID,
    where: 'member_namespace_id IS NULL'
  end

  def down
    remove_concurrent_index_by_name :members, name: TMP_INDEX_FOR_NULL_MEMBER_NAMESPACE_ID
  end
end
