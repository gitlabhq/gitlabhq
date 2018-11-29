class AddPagesHttpsOnlyToProjects < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :projects, :pages_https_only, :boolean
  end
end
