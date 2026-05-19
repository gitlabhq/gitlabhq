# frozen_string_literal: true

class AddProjectRepositoriesProjectIdForeignKey < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.0'

  def up
    add_concurrent_foreign_key :project_repositories, :projects,
      column: :project_id, target_column: :id,
      on_delete: :cascade, validate: false
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :project_repositories, column: :project_id
    end
  end
end
