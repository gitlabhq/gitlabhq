class AddMirrorCredentialsToRemoteMirrors < ActiveRecord::Migration
  def change
    add_column :remote_mirrors, :encrypted_credentials, :text
    add_column :remote_mirrors, :encrypted_credentials_iv, :text
    add_column :remote_mirrors, :encrypted_credentials_salt, :text
  end
end
