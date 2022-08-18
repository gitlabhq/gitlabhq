# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveTmpIndexProjectMembershipNamespaceIdColumn < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'tmp_index_for_namespace_id_migration_on_project_members'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :members, INDEX_NAME
  end

  def down
    add_concurrent_index :members, :id,
    where: "members.member_namespace_id IS NULL and members.type = 'ProjectMember'",
    name: INDEX_NAME
  end
end
