# frozen_string_literal: true

class AddEpicBoardList < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless table_exists?(:boards_epic_lists)
      with_lock_retries do
        create_table :boards_epic_lists do |t|
          t.timestamps_with_timezone
          t.references :epic_board, index: true, foreign_key: { to_table: :boards_epic_boards, on_delete: :cascade }, null: false
          t.references :label, index: true, foreign_key: { on_delete: :cascade }
          t.integer :position
          t.integer :list_type, default: 1, limit: 2, null: false

          t.index [:epic_board_id, :label_id], unique: true, where: 'list_type = 1', name: 'index_boards_epic_lists_on_epic_board_id_and_label_id'
        end
      end
    end

    add_check_constraint :boards_epic_lists, '(list_type <> 1) OR ("position" IS NOT NULL AND "position" >= 0)', 'boards_epic_lists_position_constraint'
  end

  def down
    with_lock_retries do
      drop_table :boards_epic_lists
    end
  end
end
