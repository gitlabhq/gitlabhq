# frozen_string_literal: true

class RemoveTmpIndexesFromMembers < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  disable_ddl_transaction!

  INDEX_NAME_ACTIVE_GROUP_MEMBERS = :tmp_idx_members_for_active_group_members
  INDEX_NAME_GROUP_MEMBERS_WITH_MEMBER_ROLE = :tmp_idx_members_for_group_members_with_member_role
  TABLE_NAME = :members

  def up
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME_ACTIVE_GROUP_MEMBERS
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME_GROUP_MEMBERS_WITH_MEMBER_ROLE
  end

  def down
    add_concurrent_index(
      TABLE_NAME,
      :id,
      where: "source_type = 'Namespace' AND state = 0 AND user_id IS NOT NULL AND requested_at IS NULL",
      name: INDEX_NAME_ACTIVE_GROUP_MEMBERS
    )

    add_concurrent_index(
      TABLE_NAME,
      [:id, :source_id],
      where: "member_role_id IS NOT NULL AND source_type = 'Namespace' AND state = 0",
      name: INDEX_NAME_GROUP_MEMBERS_WITH_MEMBER_ROLE
    )
  end
end
