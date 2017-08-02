# rubocop:disable Migration/Timestamps
class CreateChatTeams < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = true
  DOWNTIME_REASON = "Adding a foreign key"

  disable_ddl_transaction!

  def change
    create_table :chat_teams do |t|
      t.references :namespace, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
      t.string :team_id
      t.string :name

      t.timestamps null: false
    end
  end
end
