class AddWebsiteUrlToUsers < ActiveRecord::Migration
  def change
    add_column :users, :website_url, :string, {:null => false, :default => ''}
  end
end
