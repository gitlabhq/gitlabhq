# frozen_string_literal: true

class AddEpicBoardRecentVisitsTable < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  def up
    with_lock_retries do
      unless table_exists?(:boards_epic_board_recent_visits)
        create_table :boards_epic_board_recent_visits do |t|
          t.references :user, index: true, null: false, foreign_key: { on_delete: :cascade }
          t.references :epic_board, index: true, foreign_key: { to_table: :boards_epic_boards, on_delete: :cascade }, null: false
          t.references :group, index: true, foreign_key: { to_table: :namespaces, on_delete: :cascade }, null: false
          t.timestamps_with_timezone null: false
        end
      end
    end
  end

  def down
    with_lock_retries do
      drop_table :boards_epic_board_recent_visits
    end
  end
end
