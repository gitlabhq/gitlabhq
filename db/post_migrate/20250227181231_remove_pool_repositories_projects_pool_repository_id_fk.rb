# frozen_string_literal: true

class RemovePoolRepositoriesProjectsPoolRepositoryIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.11'
  disable_ddl_transaction!

  FOREIGN_KEY_NAME = "fk_6e5c14658a"

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:projects, :pool_repositories,
        name: FOREIGN_KEY_NAME, reverse_lock_order: true)
    end
  end

  def down
    add_concurrent_foreign_key(:projects, :pool_repositories,
      name: FOREIGN_KEY_NAME, column: :pool_repository_id,
      target_column: :id, on_delete: :nullify)
  end
end
