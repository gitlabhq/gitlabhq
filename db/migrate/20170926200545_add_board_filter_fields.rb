class AddBoardFilterFields < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column :boards, :weight, :integer, index: true
    add_reference :boards, :assignee, index: true

    add_concurrent_foreign_key :boards, :users, column: :assignee_id, on_delete: :nullify
  end

  def down
    remove_column :boards, :weight

    remove_foreign_key :boards, column: :assignee_id
    remove_reference :boards, :assignee
  end
end
