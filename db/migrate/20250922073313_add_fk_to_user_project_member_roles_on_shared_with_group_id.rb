# frozen_string_literal: true

class AddFkToUserProjectMemberRolesOnSharedWithGroupId < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :user_project_member_roles, :namespaces,
      column: :shared_with_group_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :user_project_member_roles, column: :shared_with_group_id
    end
  end
end
