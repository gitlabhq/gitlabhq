class AddHasExternalWikiToProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  def change
    add_column :projects, :has_external_wiki, :boolean
  end
end
