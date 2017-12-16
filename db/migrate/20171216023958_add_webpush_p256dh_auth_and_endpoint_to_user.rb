class AddWebpushP256dhAuthAndEndpointToUser < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    add_column :users, :webpush_p256dh, :string
    add_column :users, :webpush_auth, :string
    add_column :users, :webpush_endpoint, :string
  end

  def down
    remove_column :users, :webpush_p256dh
    remove_column :users, :webpush_auth
    remove_column :users, :webpush_endpoint
  end
end
