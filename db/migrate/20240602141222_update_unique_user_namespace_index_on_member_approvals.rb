# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class UpdateUniqueUserNamespaceIndexOnMemberApprovals < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  disable_ddl_transaction!

  OLD_INDEX_NAME = 'unique_index_member_approvals_on_pending_status'
  NEW_INDEX_NAME = 'unique_idx_member_approvals_on_pending_status'

  def up
    add_concurrent_index :member_approvals, [:user_id, :member_namespace_id],
      unique: true, where: "status = 0", name: NEW_INDEX_NAME

    remove_concurrent_index_by_name :member_approvals, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :member_approvals, [:user_id, :member_namespace_id, :new_access_level, :member_role_id],
      unique: true, where: "status = 0", name: OLD_INDEX_NAME

    remove_concurrent_index_by_name :member_approvals, NEW_INDEX_NAME
  end
end
