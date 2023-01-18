# frozen_string_literal: true

class IndexMembersOnMemberNamespaceIdCompoundSync < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_members_on_member_namespace_id_compound'

  disable_ddl_transaction!

  def up
    add_concurrent_index(
      :members,
      [:member_namespace_id, :type, :requested_at, :id],
      name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_index_by_name :members, INDEX_NAME
  end
end
