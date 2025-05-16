# frozen_string_literal: true

class AddIndexProjectIdOnProjectAuthorizationsForMigration < Gitlab::Database::Migration[2.3]
  milestone '18.0'

  def change
    add_index :project_authorizations_for_migration, # rubocop:disable Migration/AddIndex -- table is empty
      %i[project_id user_id],
      name: 'index_project_authorizations_for_migration_on_project_user'
  end
end
