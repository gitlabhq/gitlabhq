# frozen_string_literal: true

class AddIndexForMemberExpiringQuery < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_members_on_expiring_at_access_level_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :members,
      [:expires_at, :access_level, :id],
      where: 'requested_at IS NULL AND expiry_notified_at IS NULL',
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :members, INDEX_NAME
  end
end
