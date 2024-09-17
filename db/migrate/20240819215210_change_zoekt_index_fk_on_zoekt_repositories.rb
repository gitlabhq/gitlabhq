# frozen_string_literal: true

class ChangeZoektIndexFkOnZoektRepositories < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.4'

  NEW_CONSTRAINT_NAME = 'fk_zoekt_repositories_on_zoekt_index_id'

  def up
    add_concurrent_foreign_key(:zoekt_repositories, :zoekt_indices, column: :zoekt_index_id, on_delete: :restrict,
      validate: false, name: NEW_CONSTRAINT_NAME)
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(:zoekt_repositories, column: :zoekt_index_id, on_delete: :restrict,
        name: NEW_CONSTRAINT_NAME)
    end
  end
end
