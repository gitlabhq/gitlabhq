# rubocop:disable RemoveIndex
class AddIndexToMilestoneIdOnBoards < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index(:boards, :milestone_id)
  end

  def down
    remove_index(:boards, :milestone_id)
  end
end
