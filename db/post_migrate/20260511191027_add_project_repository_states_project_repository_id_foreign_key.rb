# frozen_string_literal: true

class AddProjectRepositoryStatesProjectRepositoryIdForeignKey < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.0'

  def up
    add_concurrent_foreign_key :project_repository_states, :project_repositories,
      column: :project_repository_id, target_column: :id,
      on_delete: :cascade, validate: false
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :project_repository_states, :project_repositories,
        column: :project_repository_id, reverse_lock_order: true
    end
  end
end
