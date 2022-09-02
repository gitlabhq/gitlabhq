# frozen_string_literal: true

class CreateGhostUserMigrations < Gitlab::Database::Migration[2.0]
  def change
    create_table :ghost_user_migrations do |t|
      t.bigint :user_id, index: { unique: true }, null: false
      t.bigint :initiator_user_id
      t.timestamps_with_timezone null: false
      t.boolean :hard_delete, default: false, null: false
    end
  end
end
