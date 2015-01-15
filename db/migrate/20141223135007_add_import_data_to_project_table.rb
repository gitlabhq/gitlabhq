class AddImportDataToProjectTable < ActiveRecord::Migration
  def change
    add_column :projects, :import_type, :string
    add_column :projects, :import_source, :string

    add_column :users, :github_access_token, :string
  end
end
