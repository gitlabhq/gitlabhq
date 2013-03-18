class AddSnippetsToFeatures < ActiveRecord::Migration
  def change
    add_column :projects, :snippets_enabled, :boolean, null: false, default: true
  end
end
