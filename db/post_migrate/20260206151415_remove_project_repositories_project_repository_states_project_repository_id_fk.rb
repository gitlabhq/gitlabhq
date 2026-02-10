# frozen_string_literal: true

class RemoveProjectRepositoriesProjectRepositoryStatesProjectRepositoryIdFk < Gitlab::Database::Migration[2.3]
  milestone '18.9'
  disable_ddl_transaction!

  FOREIGN_KEY_NAME = "fk_57201a9be7"

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:project_repository_states, :project_repositories,
        name: FOREIGN_KEY_NAME, reverse_lock_order: true)
    end
  end

  def down
    add_concurrent_foreign_key(:project_repository_states, :project_repositories,
      name: FOREIGN_KEY_NAME, column: :project_repository_id,
      target_column: :id, on_delete: :cascade)
  end
end
