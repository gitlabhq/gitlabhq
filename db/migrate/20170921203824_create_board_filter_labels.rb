class CreateBoardFilterLabels < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table :board_filter_labels do |t|
      t.integer :board_filter_id, null: false, index: true
      t.integer :label_id, null: false, index: true
    end

    add_concurrent_foreign_key :board_filter_labels, :board_filters, column: :board_filter_id, on_delete: :cascade
    add_concurrent_foreign_key :board_filter_labels, :labels, column: :label_id, on_delete: :cascade
  end

  def down
    drop_table :board_filter_labels
  end
end
