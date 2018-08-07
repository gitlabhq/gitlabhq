class AddMilestoneToLists < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_reference :lists, :milestone, index: true, foreign_key: { on_delete: :cascade }
  end
end
