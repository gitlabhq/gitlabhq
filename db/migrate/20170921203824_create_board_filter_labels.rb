class CreateBoardFilterLabels < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :board_filter_labels do |t|
      t.integer :board_filter_id, null: false, index: true
      t.integer :label_id, null: false, index: true
    end

    add_foreign_key :board_filter_labels, :board_filters, column: :board_filter_id, on_delete: :cascade
    add_foreign_key :board_filter_labels, :labels, column: :label_id, on_delete: :cascade
  end
end
