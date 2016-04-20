class AddEventFieldForWebHook < ActiveRecord::Migration
  def change
    add_column :web_hooks, :wiki_page_events, :boolean, default: false, null: false
  end
end
