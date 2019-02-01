class EnableSslVerificationByDefault < ActiveRecord::Migration[4.2]
  def change
    change_column :web_hooks, :enable_ssl_verification, :boolean, default: true
  end
end
