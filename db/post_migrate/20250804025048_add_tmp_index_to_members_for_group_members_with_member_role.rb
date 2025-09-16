# frozen_string_literal: true

class AddTmpIndexToMembersForGroupMembersWithMemberRole < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  disable_ddl_transaction!

  INDEX_NAME = :tmp_idx_members_for_group_members_with_member_role
  TABLE_NAME = :members
  CONSTRAINT = "member_role_id IS NOT NULL AND source_type = 'Namespace' AND state = 0"

  def up
    add_concurrent_index TABLE_NAME, [:id, :source_id], name: INDEX_NAME, where: CONSTRAINT
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end
