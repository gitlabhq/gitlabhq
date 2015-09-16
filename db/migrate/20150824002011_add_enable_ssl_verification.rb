class AddEnableSslVerification < ActiveRecord::Migration
  def change
    add_column :web_hooks, :enable_ssl_verification, :boolean, default: false
  end
end
