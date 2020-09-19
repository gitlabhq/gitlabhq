# frozen_string_literal: true

class RemoveUsersBioColumn < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      remove_column :users, :bio
    end
  end

  def down
    with_lock_retries do
      add_column :users, :bio, :string # rubocop: disable Migration/AddColumnsToWideTables
    end
  end
end
