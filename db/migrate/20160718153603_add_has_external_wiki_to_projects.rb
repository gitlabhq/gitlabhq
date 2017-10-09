class AddHasExternalWikiToProjects < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  def change
    add_column :projects, :has_external_wiki, :boolean
  end
end
