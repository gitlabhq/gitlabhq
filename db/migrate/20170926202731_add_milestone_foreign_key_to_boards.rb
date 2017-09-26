class AddMilestoneForeignKeyToBoards < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :boards, :milestones, column: :milestone_id, on_delete: :nullify
  end

  def down
    remove_foreign_key :boards, column: :milestone_id
  end
end
