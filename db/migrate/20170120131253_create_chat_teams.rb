class CreateChatTeams < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :chat_teams do |t|
      t.integer :group_id, index: true
      t.string :team_id
      t.string :name

      t.timestamps null: false
    end

    add_foreign_key :chat_teams, :groups, on_delete: :cascade
  end
end
