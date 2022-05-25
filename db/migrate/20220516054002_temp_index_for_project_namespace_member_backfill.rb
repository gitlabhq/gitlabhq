# frozen_string_literal: true

class TempIndexForProjectNamespaceMemberBackfill < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'tmp_index_for_namespace_id_migration_on_project_members'

  disable_ddl_transaction!

  def up
    # Temporary index to be removed in future
    # https://gitlab.com/gitlab-org/gitlab/-/issues/356509
    add_concurrent_index :members, :id,
      where: "members.member_namespace_id IS NULL and members.type = 'ProjectMember'",
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :members, INDEX_NAME
  end
end
