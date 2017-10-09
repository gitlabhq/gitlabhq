# rubocop:disable all
class AddMoreFieldsToService < ActiveRecord::Migration[4.2]
  def change
    add_column :services, :subdomain, :string
    add_column :services, :room, :string
  end
end
