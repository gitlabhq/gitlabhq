# frozen_string_literal: true

class RemoveForeignKeyProjectRepositoryStates < Gitlab::Database::Migration[2.2]
  milestone '16.10'

  disable_ddl_transaction!

  FOREIGN_KEY_NAME_PROJECTS = "fk_rails_0f2298ca8a"

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:project_repository_states, :projects,
        name: FOREIGN_KEY_NAME_PROJECTS, reverse_lock_order: true)
    end
  end

  def down
    add_concurrent_foreign_key(:project_repository_states, :projects,
      name: FOREIGN_KEY_NAME_PROJECTS, column: :project_id,
      target_column: :id, on_delete: :cascade)
  end
end
