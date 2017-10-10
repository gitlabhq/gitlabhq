class CreateBoardLabels < ActiveRecord::Migration
  DOWNTIME = false

  disable_ddl_transaction!

  def change
    create_table :board_labels do |t|
      t.references :board, index: true, foreign_key: { on_delete: :cascade }, null: false
      t.references :label, index: true, foreign_key: { on_delete: :cascade }, null: false
      t.index [:board_id, :label_id], unique: true
    end
  end
end
