class CreateBoardFiltersTable < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table :board_filters do |t|
      t.integer :board_id, null: false, index: true

      t.integer :milestone_id, index: true
      t.integer :weight, index: true
      t.integer :author_id, index: true
      t.integer :assignee_id, index: true
    end

    add_concurrent_foreign_key :board_filters, :boards, column: :board_id, on_delete: :cascade
    add_concurrent_foreign_key :board_filters, :milestones, column: :milestone_id, on_delete: :nullify
    add_concurrent_foreign_key :board_filters, :users, column: :author_id, on_delete: :nullify
    add_concurrent_foreign_key :board_filters, :users, column: :assignee_id, on_delete: :nullify
  end

  def down
    drop_table :board_filters
  end
end
