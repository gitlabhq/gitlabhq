class AddNameToJob < ActiveRecord::Migration
  def change
    add_column :jobs, :name, :string
  end
end
