# rubocop:disable all
class AddEventToServices < ActiveRecord::Migration[4.2]
  def change
    add_column :services, :wiki_page_events, :boolean, default: true
  end
end
