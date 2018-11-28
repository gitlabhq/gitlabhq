# rubocop:disable RemoveIndex
class RemoveBuildsEnableIndexOnProjects < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    remove_index :projects, column: :builds_enabled if index_exists?(:projects, :builds_enabled)
  end
end
