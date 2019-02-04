# rubocop:disable all
class AddEventFieldForWebHook < ActiveRecord::Migration[4.2]
  def change
    add_column :web_hooks, :wiki_page_events, :boolean, default: false, null: false
  end
end
