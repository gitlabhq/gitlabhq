# frozen_string_literal: true

class CreateBoardGroupRecentVisits < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :board_group_recent_visits, id: :bigserial do |t|
      t.timestamps_with_timezone null: false

      t.references :user, index: true, foreign_key: { on_delete: :cascade }
      t.references :board, index: true, foreign_key: { on_delete: :cascade }
      t.references :group, references: :namespace, column: :group_id, index: true
      t.foreign_key :namespaces, column: :group_id, on_delete: :cascade
    end

    add_index :board_group_recent_visits, [:user_id, :group_id, :board_id], unique: true, name: 'index_board_group_recent_visits_on_user_group_and_board'
  end
end
