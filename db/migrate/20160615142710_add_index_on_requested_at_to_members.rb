class AddIndexOnRequestedAtToMembers < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def change
    add_concurrent_index :members, :requested_at
  end
end
