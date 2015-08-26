class AddFieldsToBuilds < ActiveRecord::Migration
  def change
    add_column :builds, :name, :string
    add_column :builds, :deploy, :boolean, default: false
  end
end
