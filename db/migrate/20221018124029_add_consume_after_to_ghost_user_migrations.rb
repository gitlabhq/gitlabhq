# frozen_string_literal: true

class AddConsumeAfterToGhostUserMigrations < Gitlab::Database::Migration[2.0]
  def change
    add_column :ghost_user_migrations, :consume_after, :datetime_with_timezone, null: false, default: -> { 'NOW()' }
  end
end
