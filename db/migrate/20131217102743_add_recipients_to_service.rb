# rubocop:disable all
class AddRecipientsToService < ActiveRecord::Migration[4.2]
  def change
    add_column :services, :recipients, :text
  end
end
