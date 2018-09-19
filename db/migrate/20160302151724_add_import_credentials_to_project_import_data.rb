class AddImportCredentialsToProjectImportData < ActiveRecord::Migration
  def change
    add_column :project_import_data, :encrypted_credentials, :text
    add_column :project_import_data, :encrypted_credentials_iv, :string
    add_column :project_import_data, :encrypted_credentials_salt, :string
  end
end
