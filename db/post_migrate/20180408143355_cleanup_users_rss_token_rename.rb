class CleanupUsersRssTokenRename < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_rename :users, :rss_token, :feed_token
  end

  def down
    # rubocop:disable Migration/UpdateLargeTable
    rename_column_concurrently :users, :feed_token, :rss_token
  end
end
