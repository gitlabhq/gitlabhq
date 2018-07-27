# rubocop:disable Migration/Timestamps
class CreateUserChatNamesTable < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :chat_names do |t|
      t.integer :user_id, null: false
      t.integer :service_id, null: false
      t.string :team_id, null: false
      t.string :team_domain
      t.string :chat_id, null: false
      t.string :chat_name
      t.datetime :last_used_at
      t.timestamps null: false
    end

    add_index :chat_names, [:user_id, :service_id], unique: true
    add_index :chat_names, [:service_id, :team_id, :chat_id], unique: true
  end
end
