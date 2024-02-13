# frozen_string_literal: true

class CreateZoektRepositoryForeignKeyForZoektIndex < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.9'

  def up
    add_concurrent_foreign_key :zoekt_repositories, :zoekt_indices, column: :zoekt_index_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :zoekt_repositories, column: :zoekt_index_id
    end
  end
end
