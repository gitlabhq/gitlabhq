# frozen_string_literal: true

class AddProjectIdForeignKeyToProjectAuthorizationsForMigration < Gitlab::Database::Migration[2.3]
  milestone '18.0'

  def change
    # rubocop:disable Migration/AddConcurrentForeignKey -- table is empty
    add_foreign_key :project_authorizations_for_migration, :projects, column: :project_id, on_delete: :cascade
    # rubocop:enable Migration/AddConcurrentForeignKey
  end
end
