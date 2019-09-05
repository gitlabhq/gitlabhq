# frozen_string_literal: true

class AddIndexOnUsersUnconfirmedEmail < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :users, :unconfirmed_email, where: 'unconfirmed_email IS NOT NULL'
  end

  def down
    remove_concurrent_index :users, :unconfirmed_email, where: 'unconfirmed_email IS NOT NULL'
  end
end
