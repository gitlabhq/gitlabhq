# frozen_string_literal: true

class RegenRemoveForeignKeysUserInteractedProjects < Gitlab::Database::Migration[2.2]
  milestone '16.10'

  disable_ddl_transaction!

  FOREIGN_KEY_NAME_USERS = "fk_0894651f08"
  FOREIGN_KEY_NAME_PROJECTS = "fk_722ceba4f7"

  def up
    return unless table_exists?(:user_interacted_projects)

    with_lock_retries do
      remove_foreign_key_if_exists(:user_interacted_projects, :users,
        name: FOREIGN_KEY_NAME_USERS, reverse_lock_order: true)
    end

    with_lock_retries do
      remove_foreign_key_if_exists(:user_interacted_projects, :projects,
        name: FOREIGN_KEY_NAME_PROJECTS, reverse_lock_order: true)
    end
  end

  def down
    return unless table_exists?(:user_interacted_projects)

    add_concurrent_foreign_key(:user_interacted_projects, :users,
      name: FOREIGN_KEY_NAME_USERS, column: :user_id,
      target_column: :id, on_delete: :cascade)

    add_concurrent_foreign_key(:user_interacted_projects, :projects,
      name: FOREIGN_KEY_NAME_PROJECTS, column: :project_id,
      target_column: :id, on_delete: :cascade)
  end
end
