class AddRepositoryReadOnlyToProjects < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :projects, :repository_read_only, :boolean
  end
end
