class DropAndReaddHasExternalWikiInProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def up
    remove_column :projects, :has_external_wiki, :boolean
    add_column :projects, :has_external_wiki, :boolean
  end

  def down
  end
end
