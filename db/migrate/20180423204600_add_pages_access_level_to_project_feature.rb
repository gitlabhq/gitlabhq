class AddPagesAccessLevelToProjectFeature < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  DOWNTIME = false

  # rubocop: disable Migration/UpdateLargeTable
  # rubocop: disable Migration/AddColumnWithDefault
  def up
    add_column_with_default(:project_features, :pages_access_level, :integer, default: ProjectFeature::PUBLIC, allow_null: false)

    change_column_default(:project_features, :pages_access_level, ProjectFeature::ENABLED)
  end
  # rubocop: enable Migration/UpdateLargeTable
  # rubocop: enable Migration/AddColumnWithDefault

  def down
    remove_column :project_features, :pages_access_level
  end
end
