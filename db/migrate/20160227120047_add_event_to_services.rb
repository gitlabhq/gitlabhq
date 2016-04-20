class AddEventToServices < ActiveRecord::Migration
  def change
    add_column :services, :wiki_page_events, :boolean, default: true
  end
end
