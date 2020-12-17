# frozen_string_literal: true

class AddEpicBoardLabels < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    with_lock_retries do
      create_table :boards_epic_board_labels do |t|
        t.references :epic_board, index: true, foreign_key: { to_table: :boards_epic_boards, on_delete: :cascade }, null: false
        t.references :label, index: true, foreign_key: { on_delete: :cascade }, null: false
      end
    end
  end

  def down
    with_lock_retries do
      drop_table :boards_epic_board_labels
    end
  end
end
