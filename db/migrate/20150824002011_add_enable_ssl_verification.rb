# rubocop:disable all
class AddEnableSslVerification < ActiveRecord::Migration[4.2]
  def change
    add_column :web_hooks, :enable_ssl_verification, :boolean, default: false
  end
end
