class AddRssTokenToUsers < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column :users, :rss_token, :string

    add_concurrent_index :users, :rss_token
  end

  def down
    remove_concurrent_index :users, :rss_token if index_exists? :users, :rss_token

    remove_column :users, :rss_token
  end
end
