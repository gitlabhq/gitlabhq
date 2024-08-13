# frozen_string_literal: true

class AddForeignKeyToPackagesDependenciesProjectId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.3'

  def up
    add_concurrent_foreign_key :packages_dependencies, :projects, column: :project_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :packages_dependencies, column: :project_id
    end
  end
end
