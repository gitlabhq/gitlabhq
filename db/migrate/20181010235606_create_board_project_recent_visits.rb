# frozen_string_literal: true

class CreateBoardProjectRecentVisits < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :board_project_recent_visits, id: :bigserial do |t|
      t.timestamps_with_timezone null: false

      t.references :user, index: true, foreign_key: { on_delete: :cascade }
      t.references :project, index: true, foreign_key: { on_delete: :cascade }
      t.references :board, index: true, foreign_key: { on_delete: :cascade }
    end

    add_index :board_project_recent_visits, [:user_id, :project_id, :board_id], unique: true, name: 'index_board_project_recent_visits_on_user_project_and_board'
  end
end
