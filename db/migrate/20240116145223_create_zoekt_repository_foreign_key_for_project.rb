# frozen_string_literal: true

class CreateZoektRepositoryForeignKeyForProject < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.9'

  def up
    add_concurrent_foreign_key :zoekt_repositories, :projects, column: :project_id, on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key :zoekt_repositories, column: :project_id
    end
  end
end
