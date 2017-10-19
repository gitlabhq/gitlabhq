class CreateBoardAssignees < ActiveRecord::Migration
  DOWNTIME = false

  disable_ddl_transaction!

  def change
    create_table :board_assignees do |t|
      t.references :board, foreign_key: { on_delete: :cascade }, null: false
      t.integer :assignee_id, null: false
      t.foreign_key :users, column: :assignee_id, on_delete: :cascade
      t.index [:board_id, :assignee_id], unique: true
    end
  end
end
