# rubocop:disable RemoveIndex
class AddIndexToMirrorsLastUpdateAtFields < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :projects, :mirror_last_successful_update_at unless index_exists? :projects, :mirror_last_successful_update_at
    add_concurrent_index :remote_mirrors, :last_successful_update_at unless index_exists? :remote_mirrors, :last_successful_update_at
  end

  def down
    remove_index :projects, :mirror_last_successful_update_at if index_exists? :projects, :mirror_last_successful_update_at
    remove_index :remote_mirrors, :last_successful_update_at if index_exists? :remote_mirrors, :last_successful_update_at
  end
end
