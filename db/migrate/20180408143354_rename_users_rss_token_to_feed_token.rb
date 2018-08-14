class RenameUsersRssTokenToFeedToken < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # rubocop:disable Migration/UpdateLargeTable
    rename_column_concurrently :users, :rss_token, :feed_token
  end

  def down
    cleanup_concurrent_column_rename :users, :feed_token, :rss_token
  end
end
