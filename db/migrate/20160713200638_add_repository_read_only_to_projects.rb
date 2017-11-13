class AddRepositoryReadOnlyToProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :projects, :repository_read_only, :boolean
  end
end
