class RemoveBuildsEnableIndexOnProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    remove_index :projects, column: :builds_enabled if index_exists?(:projects, :builds_enabled)
  end
end
