# frozen_string_literal: true

class CreateBannedUsers < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def up
    with_lock_retries do
      create_table :banned_users, id: false do |t|
        t.timestamps_with_timezone null: false
        t.references :user, primary_key: true, default: nil, foreign_key: { on_delete: :cascade }, type: :bigint, index: false, null: false
      end
    end
  end

  def down
    with_lock_retries do
      drop_table :banned_users
    end
  end
end
