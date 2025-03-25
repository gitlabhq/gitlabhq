# frozen_string_literal: true

class RemoveProjectsPoolRepositoriesSourceProjectIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.11'
  disable_ddl_transaction!

  FOREIGN_KEY_NAME = "fk_rails_d2711daad4"

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:pool_repositories, :projects,
        name: FOREIGN_KEY_NAME, reverse_lock_order: true)
    end
  end

  def down
    add_concurrent_foreign_key(:pool_repositories, :projects,
      name: FOREIGN_KEY_NAME, column: :source_project_id,
      target_column: :id, on_delete: :nullify)
  end
end
