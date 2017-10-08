# rubocop:disable all
class AddSnippetsToFeatures < ActiveRecord::Migration[4.2]
  def change
    add_column :projects, :snippets_enabled, :boolean, null: false, default: true
  end
end
