class AddRepositoryAccessLevelToProjectFeature < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  DOWNTIME = false

  def up
    add_column_with_default(:project_features, :repository_access_level, :integer, default: ProjectFeature::ENABLED)
  end

  def down
    remove_column :project_features, :repository_access_level
  end
end
