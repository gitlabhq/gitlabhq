# frozen_string_literal: true

class CreateUserHighestRoles < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      create_table :user_highest_roles, id: false do |t|
        t.datetime_with_timezone :updated_at, null: false
        t.references :user, primary_key: true, default: nil, index: false, foreign_key: { on_delete: :cascade }
        t.integer :highest_access_level

        t.index [:user_id, :highest_access_level]
      end
    end
  end

  def down
    with_lock_retries do
      drop_table :user_highest_roles
    end
  end
end
