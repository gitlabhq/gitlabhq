# frozen_string_literal: true

class CreateUserDetails < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      create_table :user_details, id: false do |t|
        t.references :user, index: false, foreign_key: { on_delete: :cascade }, null: false, primary_key: true
        t.string :job_title, limit: 200, default: "", null: false
      end
    end

    add_index :user_details, :user_id, unique: true
  end

  def down
    with_lock_retries do
      drop_table :user_details
    end
  end
end
