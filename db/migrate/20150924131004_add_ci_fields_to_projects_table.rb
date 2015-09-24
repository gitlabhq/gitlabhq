class AddCiFieldsToProjectsTable < ActiveRecord::Migration
  def up
    add_column :projects, :shared_runners_enabled, :boolean, default: false
  end
end
