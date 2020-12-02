# frozen_string_literal: true

class AddEpicBoards < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    with_lock_retries do
      create_table :boards_epic_boards do |t|
        t.boolean :hide_backlog_list, default: false, null: false
        t.boolean :hide_closed_list, default: false, null: false
        t.references :group, index: true, foreign_key: { to_table: :namespaces, on_delete: :cascade }, null: false
        t.timestamps_with_timezone
        t.text :name, default: 'Development', null: false
      end
    end

    add_text_limit :boards_epic_boards, :name, 255
  end

  def down
    with_lock_retries do
      drop_table :boards_epic_boards
    end
  end
end
