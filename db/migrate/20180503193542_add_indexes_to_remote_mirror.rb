class AddIndexesToRemoteMirror < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :remote_mirrors, :last_successful_update_at unless index_exists?(:remote_mirrors, :last_successful_update_at)
  end

  def down
    # rubocop:disable Migration/RemoveIndex
    remove_index :remote_mirrors, :last_successful_update_at if index_exists? :remote_mirrors, :last_successful_update_at
  end
end
