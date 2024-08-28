# frozen_string_literal: true

class RemoveCascadeDeleteZoektIndexFkOnZoektRepositories < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.4'

  OLD_CONSTRAINT_NAME = "fk_94edfec0da"

  # new foreign key added in ChangeZoektIndexFkOnZoektRepositories migration
  # and validated in ValidateZoektIndexFkChangeOnZoektRepositories migration
  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:zoekt_repositories, column: :zoekt_index_id, on_delete: :cascade,
        name: OLD_CONSTRAINT_NAME)
    end
  end

  def down
    # Validation is skipped here, so if rolled back, this will need to be revalidated in a separate migration
    add_concurrent_foreign_key(:zoekt_repositories, :zoekt_indices, column: :zoekt_index_id, on_delete: :cascade,
      name: OLD_CONSTRAINT_NAME)
  end
end
