class AddMoreFieldsToService < ActiveRecord::Migration
  def change
    add_column :services, :subdomain, :string
    add_column :services, :room, :string
  end
end
