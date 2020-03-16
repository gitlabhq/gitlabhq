# frozen_string_literal: true

class AddUserTypeIndex < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :users, :user_type
  end

  def down
    remove_concurrent_index :users, :user_type
  end
end
