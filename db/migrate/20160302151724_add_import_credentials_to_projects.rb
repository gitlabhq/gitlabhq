class AddImportCredentialsToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :encrypted_import_credentials, :text
    add_column :projects, :encrypted_import_credentials_iv, :text
  end
end
