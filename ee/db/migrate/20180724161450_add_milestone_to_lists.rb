class AddMilestoneToLists < ActiveRecord::Migration
  DOWNTIME = false

  def up
    add_reference :lists, :milestone, index: true, foreign_key: { on_delete: :cascade }
  end

  def down
    remove_reference :lists, :milestone, foreign_key: true
  end
end
