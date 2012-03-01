class AddWikiEnabledToProject < ActiveRecord::Migration
  def change
    add_column :projects, :wiki_enabled, :boolean, :default => true, :null => false

  end
end
