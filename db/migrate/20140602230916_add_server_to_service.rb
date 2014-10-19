class AddServerToService < ActiveRecord::Migration
  def change
    add_column :services, :server, :string
  end
end
