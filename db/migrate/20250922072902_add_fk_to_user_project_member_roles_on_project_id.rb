# frozen_string_literal: true

class AddFkToUserProjectMemberRolesOnProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :user_project_member_roles, :projects, column: :project_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :user_project_member_roles, column: :project_id
    end
  end
end
