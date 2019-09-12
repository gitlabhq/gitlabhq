# frozen_string_literal: true

class AddIndexToMembersOnExpiresAt < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :members, :expires_at
  end

  def down
    remove_concurrent_index :members, :expires_at
  end
end
