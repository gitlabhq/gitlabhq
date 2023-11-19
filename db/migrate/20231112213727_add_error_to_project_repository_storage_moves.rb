# frozen_string_literal: true

class AddErrorToProjectRepositoryStorageMoves < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.7'

  def up
    with_lock_retries do
      add_column :project_repository_storage_moves, :error_message, :text, if_not_exists: true
    end

    add_text_limit :project_repository_storage_moves, :error_message, 256
  end

  def down
    with_lock_retries do
      remove_column :project_repository_storage_moves, :error_message, if_exists: true
    end
  end
end
