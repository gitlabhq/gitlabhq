# frozen_string_literal: true

class AddUserType < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :users, :user_type, :integer, limit: 2
    end
  end

  def down
    with_lock_retries do
      remove_column :users, :user_type
    end
  end
end
