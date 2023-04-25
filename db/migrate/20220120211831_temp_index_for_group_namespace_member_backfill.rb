# frozen_string_literal: true

class TempIndexForGroupNamespaceMemberBackfill < Gitlab::Database::Migration[1.0]
  INDEX_NAME = 'tmp_index_for_namespace_id_migration_on_group_members'

  disable_ddl_transaction!

  def up
    # Temporary index to be removed in 14.10
    # https://gitlab.com/gitlab-org/gitlab/-/issues/353538
    add_concurrent_index :members, :id, where: "members.member_namespace_id IS NULL and members.type = 'GroupMember'", name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :members, INDEX_NAME
  end
end
