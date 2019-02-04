class RenameRepositoriesPoolRepositories < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  # This change doesn't require downtime as the table is not in use, so we're
  # free to change an empty table
  DOWNTIME = false

  def change
    rename_table :repositories, :pool_repositories
  end
end
