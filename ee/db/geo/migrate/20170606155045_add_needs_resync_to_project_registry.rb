class AddNeedsResyncToProjectRegistry < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:project_registry, :resync_repository, :boolean, default: true)
    add_column_with_default(:project_registry, :resync_wiki, :boolean, default: true)
  end

  def down
    remove_columns :project_registry, :resync_repository, :resync_wiki
  end
end
