# rubocop:disable RemoveIndex
class AddIndexOnRequestedAtToMembers < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :members, :requested_at
  end

  def down
    remove_index :members, :requested_at if index_exists? :members, :requested_at
  end
end
